#!/bin/bash
# Codex PreToolUse hook: 拦截危险 shell 命令
# JSON stdout 协议，变量通过 printf 消毒避免转义问题

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  echo '{"decision": "allow"}'
  exit 0
fi

# 危险命令
if echo "$COMMAND" | grep -qE 'rm -rf|DROP TABLE|git reset --hard|git push.*(--force|-f)|truncate|> /dev/'; then
  SAFE_CMD=$(printf '%s' "$COMMAND" | tr '"\\' '_')
  printf '{"decision": "block", "reason": "危险命令被拦截: %s"}\n' "$SAFE_CMD"
  exit 0
fi

# 未经批准的包安装
if echo "$COMMAND" | grep -qE 'npm install|pnpm add|yarn add'; then
  echo '{"decision": "block", "reason": "禁止自行安装依赖，请确认后手动操作"}'
  exit 0
fi

# 禁止 npx（统一用 pnpm exec）
if echo "$COMMAND" | grep -qE '^npx '; then
  echo '{"decision": "block", "reason": "禁止使用 npx，请使用 pnpm exec"}'
  exit 0
fi

# 网络请求
if echo "$COMMAND" | grep -qE '^curl |^wget |^nc '; then
  echo '{"decision": "block", "reason": "禁止直接发起网络请求"}'
  exit 0
fi

echo '{"decision": "allow"}'
exit 0
