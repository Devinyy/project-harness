#!/bin/bash
# PostToolUse hook: 写入文件后自动格式化
# 仅处理 ts/tsx/js/jsx/css/json 文件

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.file // empty')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

if echo "$FILE_PATH" | grep -qE '\.(ts|tsx|js|jsx|css|less|scss|json|md)$'; then
  pnpm exec prettier --write "$FILE_PATH" 2>/dev/null || true
fi

exit 0
