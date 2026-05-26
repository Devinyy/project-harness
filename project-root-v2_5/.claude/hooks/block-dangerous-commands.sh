#!/bin/bash
# PreToolUse hook: 拦截危险 shell 命令
# Exit 0 = 放行, Exit 2 = 阻止

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

# 危险命令模式
if echo "$COMMAND" | grep -qE 'rm -rf|DROP TABLE|git reset --hard|git push.*(--force|-f)|truncate|> /dev/'; then
  echo "⛔ 危险命令被拦截: $COMMAND" >&2
  exit 2
fi

# 未经批准的包安装
if echo "$COMMAND" | grep -qE 'npm install|pnpm add|yarn add'; then
  echo "⛔ 禁止自行安装依赖，请确认后手动操作" >&2
  exit 2
fi

# 禁止 npx（统一用 pnpm exec）
if echo "$COMMAND" | grep -qE '^npx '; then
  echo "⛔ 禁止使用 npx，请使用 pnpm exec" >&2
  exit 2
fi

# 网络请求（防止数据泄露）
if echo "$COMMAND" | grep -qE '^curl |^wget |^nc '; then
  echo "⛔ 禁止直接发起网络请求" >&2
  exit 2
fi

exit 0
