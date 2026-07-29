#!/bin/bash
# 跨 agent 通用脚手架：探测 flavor → 复制模版骨架到 docs/specs/ → 镜像放置目录级 AGENTS
# 确定性部分（任何 agent / 人 / CI 都能跑）。占位符 <填写：…> 的「填充」仍需 agent 按 RULE.md 完成。
#
# 用法:
#   bash scripts/init-specs.sh                 # 自动探测 flavor
#   bash scripts/init-specs.sh --flavor pc     # 强制 PC 微前端
#   bash scripts/init-specs.sh --flavor mini   # 强制 uni-app 多端
#   bash scripts/init-specs.sh --force         # 已存在也覆盖
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd -P)
. "$SCRIPT_DIR/lib/specs-state.sh"

TPL_ROOT="spec-templates"
TOKEN_TPL_ROOT="token-templates"
SPECS="docs/specs"
TOKEN_SPECS="docs/token-specs"
FLAVOR=""; FORCE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --flavor) FLAVOR="${2:-}"; shift 2 ;;
    --force)  FORCE=1; shift ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    *) echo "未知参数: $1"; exit 2 ;;
  esac
done

# 0. 先判断 specs 是否缺失、仍是草稿、或已复核激活
if [ "$FORCE" -ne 1 ]; then
  SPECS_STATE=$(specs_state ".")
  case "$SPECS_STATE" in
    active)
      echo "✋ specs state=active：项目事实已复核，跳过初始化（--force 可强制覆盖）"
      exit 0
      ;;
    draft)
      echo "✋ specs state=draft：骨架已存在但尚未复核，不覆盖现有内容。"
      echo "请按 docs/specs/_RULE.md 继续填充，并运行 bash scripts/doctor.sh --strict 验收。"
      exit 0
      ;;
  esac
fi

# 1. 探测 flavor
if [ -z "$FLAVOR" ]; then
  if [ -d "apps/micro-main" ] || grep -q '@micro-zoe/micro-app' package.json 2>/dev/null || grep -q 'dc-platform' package.json 2>/dev/null; then
    FLAVOR=pc
  elif [ -f "src/pages.json" ] || grep -qE '@dcloudio/uni-app|uview-plus' package.json 2>/dev/null; then
    FLAVOR=mini
  else
    echo "⚠️ 无法自动判定项目类型，请用 --flavor pc|mini"; exit 2
  fi
fi
case "$FLAVOR" in
  pc)   DIR="$TPL_ROOT/pc-microapp" ;;
  mini) DIR="$TPL_ROOT/miniprogram-uniapp" ;;
  *) echo "flavor 只能是 pc 或 mini"; exit 2 ;;
esac
[ -d "$DIR" ] || { echo "❌ 找不到模版目录 $DIR（请确认在 harness 已就位的项目根运行）"; exit 1; }
echo "🔎 flavor=$FLAVOR  模版=$DIR"

# 2. 复制骨架 → docs/specs/（排除 RULE.md 与 AGENTS/ 树）
mkdir -p "$SPECS"
while IFS= read -r -d '' f; do
  rel="${f#"$DIR"/}"
  mkdir -p "$SPECS/$(dirname "$rel")"
  cp "$f" "$SPECS/$rel"
done < <(find "$DIR" -type f ! -name 'RULE.md' ! -path "$DIR/AGENTS/*" -print0)
echo "✅ 已复制规格骨架 → $SPECS/"

# 2.1. PC 端设计 token → docs/token-specs/（独立于 docs/specs）
if [ "$FLAVOR" = "pc" ] && [ -d "$TOKEN_TPL_ROOT/pc" ]; then
  mkdir -p "$TOKEN_SPECS"
  while IFS= read -r -d '' f; do
    rel="${f#"$TOKEN_TPL_ROOT/pc"/}"
    mkdir -p "$TOKEN_SPECS/$(dirname "$rel")"
    if [ -f "$TOKEN_SPECS/$rel" ] && [ "$FORCE" -ne 1 ]; then
      echo "  ↷ token 已存在，跳过 $TOKEN_SPECS/$rel"
    else
      cp "$f" "$TOKEN_SPECS/$rel"
      echo "  ✅ $TOKEN_SPECS/$rel"
    fi
  done < <(find "$TOKEN_TPL_ROOT/pc" -type f -print0)
fi

# 3. 镜像放置目录级 AGENTS.md（仅当目标目录真实存在、且未占用）
if [ -d "$DIR/AGENTS" ]; then
  while IFS= read -r -d '' f; do
    rel="${f#"$DIR"/AGENTS/}"                 # 例 apps/micro-main/AGENTS.md
    target_dir="$(dirname "$rel")"
    if [ -d "$target_dir" ]; then
      if [ -f "$target_dir/AGENTS.md" ]; then
        echo "  ↷ 已存在，跳过 $target_dir/AGENTS.md"
      else
        cp "$f" "$target_dir/AGENTS.md"; echo "  ✅ $target_dir/AGENTS.md"
      fi
    else
      echo "  ↷ 目标目录不存在，略过 $target_dir/AGENTS.md"
    fi
  done < <(find "$DIR/AGENTS" -name 'AGENTS.md' -print0)
fi

# 4. 探测并写入类型检查命令（verify-before-stop hook 读取，避免写死 vue-tsc）
if [ ! -f "$SPECS/verify.cmd" ]; then
  VCMD="pnpm exec vue-tsc --noEmit"
  if [ -f package.json ]; then
    for s in lint:type validate type-check typecheck check; do
      if jq -e --arg s "$s" '.scripts[$s] // empty' package.json >/dev/null 2>&1; then
        VCMD="pnpm run $s"; break
      fi
    done
  fi
  {
    echo "# 本项目类型检查命令（verify-before-stop hook 读取首行非注释）"
    echo "# 自动探测自 package.json，按真实情况修正（如 monorepo filter）"
    echo "$VCMD"
  } > "$SPECS/verify.cmd"
  echo "✅ 写入 $SPECS/verify.cmd → $VCMD（请人工确认）"
fi

# 5. 放一份填充指引供任意 agent 参考
cp "$DIR/RULE.md" "$SPECS/_RULE.md"

cat <<'EOF'

── 脚手架完成。下一步「填充」需要 agent / 人来做（脚本不替代）──
  1. 按 docs/specs/_RULE.md 与 spec-templates/SCHEMA.md，探索真实代码取证
  2. 逐份替换 docs/specs/ 里的 <填写：…> 占位符；务必校准 docs/specs/dangerous-zones.txt
  3. PC 项目如存在 docs/token-specs/，后续色号、字号以该目录 token 为准
  4. 复核后删除 docs/specs/_RULE.md，把各文档 frontmatter 的 status 改 active

  • Claude Code：直接运行 /init-specs，agent 会自动完成探索+填充
  • Codex / Cursor / Windsurf：先跑本脚本，再让 agent「按 docs/specs/_RULE.md 填充 docs/specs 占位符」
EOF
