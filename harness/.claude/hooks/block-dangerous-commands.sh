#!/bin/bash
# PreToolUse hook: 拦截危险 shell 命令。Exit 0 放行 / 2 阻止
INPUT=$(cat)
COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd -P)
AUDIT_SCRIPT="$REPO_ROOT/scripts/record-harness-event.sh"

record_event() {
  [ -f "$AUDIT_SCRIPT" ] || return 0
  bash "$AUDIT_SCRIPT" \
    --adapter claude --event "$1" --category "$2" --decision "$3" --exit "$4" \
    >/dev/null 2>&1 || true
}

[ -z "$COMMAND" ] && exit 0
if echo "$COMMAND" | grep -qE 'rm -rf|DROP TABLE|git reset --hard|git push.*(--force|-f)|truncate|> /dev/'; then
  record_event pre_tool_use destructive_operation block 2
  echo "⛔ 危险命令被拦截: $COMMAND" >&2; exit 2; fi
if echo "$COMMAND" | grep -qE 'npm install|pnpm add|yarn add'; then
  record_event pre_tool_use dependency_install block 2
  echo "⛔ 禁止自行安装依赖，请确认后手动操作" >&2; exit 2; fi
if echo "$COMMAND" | grep -qE '^npx '; then
  record_event pre_tool_use tool_policy block 2
  echo "⛔ 禁止使用 npx，请使用 pnpm exec" >&2; exit 2; fi
if echo "$COMMAND" | grep -qE '^curl |^wget |^nc '; then
  record_event pre_tool_use network_egress block 2
  echo "⛔ 禁止直接发起网络请求" >&2; exit 2; fi
exit 0
