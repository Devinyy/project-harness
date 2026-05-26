#!/bin/bash
# Stop hook: agent 结束前验证 + 自动输出改动摘要
# Exit 0 = 允许结束, Exit 2 = 强制继续修复

INPUT=$(cat)

# 防止无限循环
if [ "$(echo "$INPUT" | jq -r '.stop_hook_active')" = "true" ]; then
  exit 0
fi

FAILED=0

# 1. 类型检查
TSC_OUTPUT=$(pnpm exec tsc --noEmit 2>&1)
if [ $? -ne 0 ]; then
  echo "❌ 类型检查未通过：" >&2
  echo "$TSC_OUTPUT" | head -20 >&2
  FAILED=1
fi

# 2. Lint（取消注释启用）
# LINT_OUTPUT=$(pnpm exec eslint --quiet . 2>&1)
# if [ $? -ne 0 ]; then
#   echo "❌ Lint 未通过：" >&2
#   echo "$LINT_OUTPUT" | head -20 >&2
#   FAILED=1
# fi

if [ $FAILED -ne 0 ]; then
  exit 2
fi

# 验证通过后，自动输出改动摘要
echo "── 本次改动 ──" >&2
git diff --stat HEAD 2>/dev/null >&2 || echo "(未在 git 仓库中)" >&2

exit 0
