#!/bin/bash
# Stop hook: 结束前类型检查 + 改动摘要。Exit 0 允许 / 2 强制继续
INPUT=$(cat)
if [ "$(echo "$INPUT" | jq -r '.stop_hook_active')" = "true" ]; then exit 0; fi
FAILED=0
TSC_OUTPUT=$(pnpm exec vue-tsc --noEmit 2>&1)
if [ $? -ne 0 ]; then
  echo "❌ 类型检查未通过（vue-tsc）：" >&2; echo "$TSC_OUTPUT" | head -20 >&2; FAILED=1
fi
# uni-app 类无单测，不要在此调用 pnpm test
if [ $FAILED -ne 0 ]; then exit 2; fi
echo "── 本次改动 ──" >&2
git diff --stat HEAD 2>/dev/null >&2 || echo "(未在 git 仓库中)" >&2
exit 0
