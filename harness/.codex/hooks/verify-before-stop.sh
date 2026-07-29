#!/bin/bash
# Codex Stop hook: fast profile + 格式化兜底 + 危险区兜底扫描 + 改动摘要

INPUT=$(cat)

emit_stop_response() {
  local should_continue="$1"
  local context="$2"
  jq -cn \
    --argjson should_continue "$should_continue" \
    --arg context "$context" \
    '{
      continue: $should_continue,
      hookSpecificOutput: {
        hookEventName: "Stop",
        additionalContext: $context
      }
    }'
}

if [ "$(echo "$INPUT" | jq -r '.stop_hook_active // false')" = "true" ]; then
  echo '{"continue": false}'
  exit 0
fi

HOOK_DIR=$(cd "$(dirname "$0")" && pwd -P)
HARNESS_ROOT=$(cd "$HOOK_DIR/../.." && pwd -P)
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd -P)
. "$HARNESS_ROOT/scripts/lib/changed-files.sh"

# === 1. 共享验证 ===
VERIFY_OUTPUT=$(
  cd "$HARNESS_ROOT" &&
    bash "$HARNESS_ROOT/scripts/verify-harness.sh" 2>&1
)
VERIFY_EXIT=$?
if [ "$VERIFY_EXIT" -ne 0 ]; then
  ERRORS=$(echo "$VERIFY_OUTPUT" | head -15 | tr '"\\' '_')
  emit_stop_response true "$(printf 'Harness fast profile 未通过：\n%s' "$ERRORS")"
  exit 0
fi

if [ -d "$HARNESS_ROOT/spec-templates" ] && [ ! -f "$HARNESS_ROOT/package.json" ]; then
  DIFF_STAT=$(git diff --stat HEAD 2>/dev/null | tr '"\\' '_' || echo "(未在 git 仓库中)")
  emit_stop_response false "$(printf '── Harness 自检通过 ──\n%s' "$DIFF_STAT")"
  exit 0
fi

CHANGED_FILES=$(changed_files "$REPO_ROOT")

# === 2. 格式化兜底（补偿 apply_patch 绕过 PostToolUse） ===
FORMAT_FILES=$(printf '%s\n' "$CHANGED_FILES" | grep -E '\.(vue|ts|js|css|less|scss|json)$' || true)
if [ -n "$FORMAT_FILES" ]; then
  (
    cd "$REPO_ROOT" &&
      printf '%s\n' "$FORMAT_FILES" |
        xargs pnpm exec prettier --write 2>/dev/null
  ) || true
fi

# === 3. 危险区兜底扫描 ===
# 优先用 docs/specs/dangerous-zones.txt；用 grep -F -f 逐行子串匹配（issue: 不要把多行塞给 grep -F "$var"）
ZONES_FILE="$REPO_ROOT/docs/specs/dangerous-zones.txt"
if [ -f "$ZONES_FILE" ]; then
  DANGER_FILES=$(printf '%s\n' "$CHANGED_FILES" | grep -F -f <(grep -vE '^\s*(#|$)' "$ZONES_FILE") 2>/dev/null || true)
else
  DANGEROUS_PATTERNS="src/utils/(request|auth)\.ts|src/(main\.ts|App\.vue|router\.ts|uni\.scss)|src/(mixin|oauth2|uni_modules|components/basic|config|constants)/|pages\.json|manifest\.json|apps/micro-main/src/|packages/(http-client|micro-bridge|auth-session|shared-types|shared-utils)/|vite\.config|tsconfig|\.env"
  DANGER_FILES=$(printf '%s\n' "$CHANGED_FILES" | grep -E "$DANGEROUS_PATTERNS" || true)
fi

if [ -n "$DANGER_FILES" ]; then
  SAFE_FILES=$(printf '%s' "$DANGER_FILES" | tr '"\\' '_')
  emit_stop_response true "$(
    printf '⚠️ 检测到危险区文件被修改：\n%s\n请确认修改是否必要，或用 git checkout 回滚。' \
      "$SAFE_FILES"
  )"
  exit 0
fi

# === 4. 改动摘要 ===
DIFF_STAT=$(printf '%s\n' "${CHANGED_FILES:-(无改动)}" | tr '"\\' '_')
emit_stop_response false "$(printf '── 本次改动 ──\n%s' "$DIFF_STAT")"
exit 0
