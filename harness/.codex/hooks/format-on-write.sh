#!/bin/bash
# Codex PostToolUse hook: Bash 命令执行后检查是否有文件写入并格式化

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if echo "$COMMAND" | grep -qE '(cat >|tee |sed -i|echo .* >)'; then
  FILE_PATH=$(echo "$COMMAND" | grep -oE '[^ ]+\.(vue|ts|js|css|less|scss|json)' | head -1)
  if [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ]; then
    pnpm exec prettier --write "$FILE_PATH" 2>/dev/null || true
  fi
fi

echo '{"continue": true}'
exit 0
