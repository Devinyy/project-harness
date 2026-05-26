#!/bin/bash
# 环境预检查脚本
# 用途：手动执行 `bash scripts/doctor.sh`，或作为 SessionStart hook 自动触发

ERRORS=0

check_command() {
  if command -v "$1" >/dev/null 2>&1; then
    echo "✅ $1 $(command -v "$1")"
  else
    echo "❌ 缺少: $1"
    ERRORS=$((ERRORS + 1))
  fi
}

echo "== Harness Doctor =="

check_command node
check_command pnpm
check_command jq
check_command git

# 项目文件检查
[ -f "package.json" ] && echo "✅ package.json" || { echo "❌ 缺少 package.json"; ERRORS=$((ERRORS + 1)); }
[ -f "tsconfig.json" ] && echo "✅ tsconfig.json" || echo "⚠️ 未检测到 tsconfig.json"

# harness 完整性检查
[ -f "CLAUDE.md" ] && echo "✅ CLAUDE.md" || echo "⚠️ 缺少 CLAUDE.md"
[ -f "AGENTS.md" ] && echo "✅ AGENTS.md" || echo "⚠️ 缺少 AGENTS.md"
[ -d ".claude/hooks" ] && echo "✅ .claude/hooks/" || echo "⚠️ 缺少 .claude/hooks/"
[ -d ".codex/hooks" ] && echo "✅ .codex/hooks/" || echo "⚠️ 缺少 .codex/hooks/"

# 检查 hooks 是否有执行权限
for hook in .claude/hooks/*.sh .codex/hooks/*.sh; do
  if [ -f "$hook" ] && [ ! -x "$hook" ]; then
    echo "⚠️ $hook 缺少执行权限，运行: chmod +x $hook"
  fi
done

if [ $ERRORS -gt 0 ]; then
  echo "== ❌ 检查未通过，有 $ERRORS 个关键缺失 =="
  exit 1
fi

echo "== ✅ 环境检查通过 =="
exit 0
