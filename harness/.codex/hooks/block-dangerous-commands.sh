#!/bin/bash
# Codex PreToolUse hook: 拦截危险 shell 命令
# JSON stdout 协议，变量通过 printf 消毒避免转义问题

INPUT=$(cat)
COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd -P)
AUDIT_SCRIPT="$REPO_ROOT/scripts/record-harness-event.sh"

record_event() {
  [ -f "$AUDIT_SCRIPT" ] || return 0
  bash "$AUDIT_SCRIPT" \
    --adapter codex --event "$1" --category "$2" --decision "$3" --exit "$4" \
    >/dev/null 2>&1 || true
}

if [ -z "$COMMAND" ]; then
  echo '{"decision": "allow"}'
  exit 0
fi

# 危险命令
if echo "$COMMAND" | grep -qE 'rm -rf|DROP TABLE|git reset --hard|git push.*(--force|-f)|truncate|> /dev/'; then
  record_event pre_tool_use destructive_operation block 0
  SAFE_CMD=$(printf '%s' "$COMMAND" | tr '"\\' '_')
  printf '{"decision": "block", "reason": "危险命令被拦截: %s"}\n' "$SAFE_CMD"
  exit 0
fi

# 未经批准的包安装
if echo "$COMMAND" | grep -qE 'npm install|pnpm add|yarn add'; then
  record_event pre_tool_use dependency_install block 0
  echo '{"decision": "block", "reason": "禁止自行安装依赖，请确认后手动操作"}'
  exit 0
fi

# 禁止 npx（统一用 pnpm exec）
if echo "$COMMAND" | grep -qE '^npx '; then
  record_event pre_tool_use tool_policy block 0
  echo '{"decision": "block", "reason": "禁止使用 npx，请使用 pnpm exec"}'
  exit 0
fi

# 网络请求
if echo "$COMMAND" | grep -qE '^curl |^wget |^nc '; then
  record_event pre_tool_use network_egress block 0
  echo '{"decision": "block", "reason": "禁止直接发起网络请求"}'
  exit 0
fi

echo '{"decision": "allow"}'
exit 0
