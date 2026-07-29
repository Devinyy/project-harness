#!/bin/bash
# Codex PreToolUse hook: 拦截 apply_patch/Edit/Write 对危险区的修改

INPUT=$(cat)
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd -P)
ZONES_FILE="$REPO_ROOT/docs/specs/dangerous-zones.txt"

FILE_PATHS=$(
  {
    printf '%s' "$INPUT" |
      jq -r '.tool_input.file_path // .tool_input.file // empty' 2>/dev/null
    printf '%s' "$INPUT" |
      jq -r '.tool_input.patch // empty' 2>/dev/null |
      sed -nE \
        -e 's/^\*\*\* (Add|Update|Delete) File: (.*)$/\2/p' \
        -e 's/^\*\*\* Move to: (.*)$/\1/p'
  } | sed '/^[[:space:]]*$/d' | LC_ALL=C sort -u
)

if [ -z "$FILE_PATHS" ]; then
  echo '{"decision": "allow"}'
  exit 0
fi

is_dangerous_path() {
  local file_path="$1"
  local pattern

  if [ -f "$ZONES_FILE" ]; then
    while IFS= read -r pattern; do
      [ -z "$pattern" ] && continue
      case "$pattern" in \#*) continue ;; esac
      if printf '%s' "$file_path" | grep -qF -- "$pattern"; then
        MATCHED_PATTERN="$pattern"
        return 0
      fi
    done < "$ZONES_FILE"
    return 1
  fi

  for pattern in \
    "src/router" "src/permission" "src/guards" "src/interceptors" \
    "src/utils/request" "src/utils/auth" "src/main.ts" "src/App.vue" \
    "pages.json" "manifest.json" "src/uni.scss" "src/components/basic/" \
    "apps/micro-main/src/" "packages/http-client/" "packages/micro-bridge/" \
    "src/config/" "vite.config" "tsconfig" ".env"; do
    if printf '%s' "$file_path" | grep -qF -- "$pattern"; then
      MATCHED_PATTERN="$pattern"
      return 0
    fi
  done
  return 1
}

while IFS= read -r file_path; do
  if is_dangerous_path "$file_path"; then
    SAFE_PATH=$(printf '%s' "$file_path" | tr '"\\' '_')
    SAFE_PATTERN=$(printf '%s' "$MATCHED_PATTERN" | tr '"\\' '_')
    printf '{"decision": "block", "reason": "危险区文件被拦截: %s（规则: %s）"}\n' \
      "$SAFE_PATH" "$SAFE_PATTERN"
    exit 0
  fi
done <<< "$FILE_PATHS"

echo '{"decision": "allow"}'
exit 0
