#!/bin/bash
# Codex Stop hook: 类型检查 + 格式化兜底 + 危险区兜底扫描 + 改动摘要

INPUT=$(cat)

if [ "$(echo "$INPUT" | jq -r '.stop_hook_active // false')" = "true" ]; then
  echo '{"continue": false}'
  exit 0
fi

HOOK_DIR=$(cd "$(dirname "$0")" && pwd -P)
HARNESS_ROOT=$(cd "$HOOK_DIR/../.." && pwd -P)

# === 1. 共享验证 ===
VERIFY_OUTPUT=$(bash "$HARNESS_ROOT/scripts/verify-harness.sh" 2>&1)
VERIFY_EXIT=$?
if [ "$VERIFY_EXIT" -ne 0 ]; then
  ERRORS=$(echo "$VERIFY_OUTPUT" | head -15 | tr '"\\' '_')
  printf '{"continue": true, "hookSpecificOutput": {"hookEventName": "Stop", "additionalContext": "Harness 验证未通过：\n%s"}}\n' "$ERRORS"
  exit 0
fi

if [ -d "$HARNESS_ROOT/spec-templates" ] && [ ! -f "$HARNESS_ROOT/package.json" ]; then
  DIFF_STAT=$(git diff --stat HEAD 2>/dev/null | tr '"\\' '_' || echo "(未在 git 仓库中)")
  printf '{"continue": false, "hookSpecificOutput": {"hookEventName": "Stop", "additionalContext": "── Harness 自检通过 ──\n%s"}}\n' "$DIFF_STAT"
  exit 0
fi

# === 2. 格式化兜底（补偿 apply_patch 绕过 PostToolUse） ===
CHANGED_FILES=$(git diff --name-only HEAD 2>/dev/null | grep -E '\.(vue|ts|js|css|less|scss|json)$' || true)
if [ -n "$CHANGED_FILES" ]; then
  echo "$CHANGED_FILES" | xargs pnpm exec prettier --write 2>/dev/null || true
fi

# === 3. 危险区兜底扫描 ===
# 优先用 docs/specs/dangerous-zones.txt；用 grep -F -f 逐行子串匹配（issue: 不要把多行塞给 grep -F "$var"）
ZONES_FILE="docs/specs/dangerous-zones.txt"
if [ -f "$ZONES_FILE" ]; then
  DANGER_FILES=$(git diff --name-only HEAD 2>/dev/null | grep -F -f <(grep -vE '^\s*(#|$)' "$ZONES_FILE") 2>/dev/null || true)
else
  DANGEROUS_PATTERNS="src/utils/(request|auth)\.ts|src/(main\.ts|App\.vue|router\.ts|uni\.scss)|src/(mixin|oauth2|uni_modules|components/basic|config|constants)/|pages\.json|manifest\.json|apps/micro-main/src/|packages/(http-client|micro-bridge|auth-session|shared-types|shared-utils)/|vite\.config|tsconfig|\.env"
  DANGER_FILES=$(git diff --name-only HEAD 2>/dev/null | grep -E "$DANGEROUS_PATTERNS" || true)
fi

if [ -n "$DANGER_FILES" ]; then
  SAFE_FILES=$(printf '%s' "$DANGER_FILES" | tr '"\\' '_')
  printf '{"continue": true, "hookSpecificOutput": {"hookEventName": "Stop", "additionalContext": "⚠️ 检测到危险区文件被修改：\n%s\n请确认修改是否必要，或用 git checkout 回滚。"}}\n' "$SAFE_FILES"
  exit 0
fi

# === 4. 改动摘要 ===
DIFF_STAT=$(git diff --stat HEAD 2>/dev/null | tr '"\\' '_' || echo "(未在 git 仓库中)")
printf '{"continue": false, "hookSpecificOutput": {"hookEventName": "Stop", "additionalContext": "── 本次改动 ──\n%s"}}\n' "$DIFF_STAT"
exit 0
