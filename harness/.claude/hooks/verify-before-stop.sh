#!/bin/bash
# Stop hook: 结束前类型检查 + 改动摘要。Exit 0 允许 / 2 强制继续
INPUT=$(cat)
if [ "$(echo "$INPUT" | jq -r '.stop_hook_active')" = "true" ]; then exit 0; fi

# 解析本项目类型检查命令（不要写死 vue-tsc）：
# docs/specs/verify.cmd（init-specs 生成）→ package.json 脚本探测 → 兜底 vue-tsc
resolve_typecheck() {
  if [ -f docs/specs/verify.cmd ]; then
    grep -vE '^\s*(#|$)' docs/specs/verify.cmd | head -1
    return
  fi
  if [ -f package.json ]; then
    local s
    for s in lint:type validate type-check typecheck check; do
      if jq -e --arg s "$s" '.scripts[$s] // empty' package.json >/dev/null 2>&1; then
        echo "pnpm run $s"; return
      fi
    done
  fi
  echo "pnpm exec vue-tsc --noEmit"
}

FAILED=0
TYPECHECK=$(resolve_typecheck)
TSC_OUTPUT=$(bash -c "$TYPECHECK" 2>&1)
if [ $? -ne 0 ]; then
  echo "❌ 类型检查未通过（$TYPECHECK）：" >&2; echo "$TSC_OUTPUT" | head -20 >&2; FAILED=1
fi
# 注：uni-app 类无单测，不要在此调用 pnpm test
if [ $FAILED -ne 0 ]; then exit 2; fi
echo "── 本次改动 ──" >&2
git diff --stat HEAD 2>/dev/null >&2 || echo "(未在 git 仓库中)" >&2
exit 0
