#!/bin/bash
# Codex Stop hook: 类型检查 + 格式化兜底 + 危险区兜底扫描 + 改动摘要

INPUT=$(cat)

if [ "$(echo "$INPUT" | jq -r '.stop_hook_active // false')" = "true" ]; then
  echo '{"continue": false}'
  exit 0
fi

# 解析本项目的类型检查命令（issue: 不要写死 vue-tsc）
# 优先级：docs/specs/verify.cmd（init-specs 生成）→ package.json 脚本探测 → 兜底 vue-tsc
resolve_typecheck() {
  if [ -f docs/specs/verify.cmd ]; then
    grep -vE '^\s*(#|$)' docs/specs/verify.cmd | head -1
    return
  fi
  if [ -f package.json ]; then
    local s
    for s in lint:type validate type-check typecheck check; do
      if jq -e --arg s "$s" '.scripts[$s] // empty' package.json >/dev/null 2>&1; then
        echo "pnpm run $s"; return
      fi
    done
  fi
  echo "pnpm exec vue-tsc --noEmit"
}

# === 1. 类型检查 ===
TYPECHECK=$(resolve_typecheck)
TSC_OUTPUT=$(bash -c "$TYPECHECK" 2>&1)
if [ $? -ne 0 ]; then
  ERRORS=$(echo "$TSC_OUTPUT" | head -15 | tr '"\\' '_')
  printf '{"continue": true, "hookSpecificOutput": {"hookEventName": "Stop", "additionalContext": "类型检查未通过（%s）：\n%s"}}\n' "$(printf '%s' "$TYPECHECK" | tr '"\\' '_')" "$ERRORS"
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
