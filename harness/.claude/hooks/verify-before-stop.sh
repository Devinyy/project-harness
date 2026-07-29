#!/bin/bash
# Stop hook: 结束前 fast profile + 改动摘要。Exit 0 允许 / 2 强制继续
INPUT=$(cat)
if [ "$(echo "$INPUT" | jq -r '.stop_hook_active')" = "true" ]; then exit 0; fi

HOOK_DIR=$(cd "$(dirname "$0")" && pwd -P)
HARNESS_ROOT=$(cd "$HOOK_DIR/../.." && pwd -P)
VERIFY_OUTPUT=$(bash "$HARNESS_ROOT/scripts/verify-harness.sh" 2>&1)
VERIFY_EXIT=$?
if [ "$VERIFY_EXIT" -ne 0 ]; then
  echo "❌ Harness fast profile 未通过：" >&2
  echo "$VERIFY_OUTPUT" | head -20 >&2
  exit 2
fi

echo "── 本次改动 ──" >&2
git diff --stat HEAD 2>/dev/null >&2 || echo "(未在 git 仓库中)" >&2
exit 0
