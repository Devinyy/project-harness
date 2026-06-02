#!/bin/bash
# PostToolUse hook: 写入后自动格式化（vue/ts/js/css/less/scss/json/md）
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.file // empty')
[ -z "$FILE_PATH" ] && exit 0
if echo "$FILE_PATH" | grep -qE '\.(vue|ts|js|css|less|scss|json|md)$'; then
  pnpm exec prettier --write "$FILE_PATH" 2>/dev/null || true
fi
exit 0
