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

# 4. 探测并写入 fast/full 验证档位
package_script_exists() {
  local script_name="$1"
  [ -f package.json ] &&
    jq -e --arg script_name "$script_name" \
      '.scripts[$script_name] // empty' package.json >/dev/null 2>&1
}

first_package_script() {
  local script_name
  for script_name in "$@"; do
    if package_script_exists "$script_name"; then
      printf '%s\n' "$script_name"
      return 0
    fi
  done
  return 1
}

matching_package_scripts() {
  local script_pattern="$1"
  [ -f package.json ] || return 0
  jq -r --arg script_pattern "$script_pattern" \
    '.scripts // {} | keys[] | select(test($script_pattern))' package.json |
    LC_ALL=C sort
}

package_has_dependency() {
  local dependency_name="$1"
  [ -f package.json ] &&
    jq -e --arg dependency_name "$dependency_name" \
      '.devDependencies[$dependency_name] // .dependencies[$dependency_name] // empty' \
      package.json >/dev/null 2>&1
}

FULL_SCRIPTS=()
FULL_SCRIPT_COUNT=0
LINT_FOUND=0
BUILD_FOUND=0
TEST_FOUND=0
SMOKE_FOUND=0
add_full_script() {
  local category="$1"
  local script_name="$2"
  local existing
  [ -n "$script_name" ] || return 0
  [ "$script_name" = "${TYPE_SCRIPT:-}" ] && return 0
  if [ "$FULL_SCRIPT_COUNT" -gt 0 ]; then
    for existing in "${FULL_SCRIPTS[@]}"; do
      [ "$existing" = "$script_name" ] && return 0
    done
  fi
  FULL_SCRIPTS[$FULL_SCRIPT_COUNT]="$script_name"
  FULL_SCRIPT_COUNT=$((FULL_SCRIPT_COUNT + 1))
  case "$category" in
    lint) LINT_FOUND=1 ;;
    build) BUILD_FOUND=1 ;;
    test) TEST_FOUND=1 ;;
    smoke) SMOKE_FOUND=1 ;;
  esac
}

# verify.cmd 是 Stop hook 使用的 fast profile，保持旧文件语义兼容。
if [ ! -f "$SPECS/verify.cmd" ]; then
  VCMD=""
  TYPE_SCRIPT=$(first_package_script lint:type validate type-check typecheck check || true)
  if [ -n "$TYPE_SCRIPT" ]; then
    VCMD="pnpm run $TYPE_SCRIPT"
  elif package_has_dependency vue-tsc; then
    VCMD="pnpm exec vue-tsc --noEmit"
  fi
  {
    echo "# fast profile：Stop hook 默认执行；一行一个命令"
    echo "# 自动探测自 package.json，按真实情况修正（如 monorepo filter）"
    if [ -n "$VCMD" ]; then
      echo "$VCMD"
    else
      echo "# typecheck: 未探测到 package script 或 vue-tsc 依赖，请人工确认"
    fi
  } > "$SPECS/verify.cmd"
  echo "✅ 写入 $SPECS/verify.cmd → ${VCMD:-未探测到 fast 命令}（请人工确认）"
else
  TYPE_SCRIPT=$(
    sed -nE 's/^[[:space:]]*pnpm run ([^[:space:]]+)[[:space:]]*$/\1/p' \
      "$SPECS/verify.cmd" |
      head -1
  )
fi

# verify.full.cmd 是可选的人工/CI 深度检查，只写入真实存在的 package scripts。
if [ ! -f "$SPECS/verify.full.cmd" ]; then
  LINT_SCRIPT=$(first_package_script lint || true)
  if [ -n "$LINT_SCRIPT" ]; then
    add_full_script lint "$LINT_SCRIPT"
  else
    while IFS= read -r script_name; do
      add_full_script lint "$script_name"
    done < <(matching_package_scripts '^lint(:|$)')
  fi

  BUILD_SCRIPT=$(first_package_script build || true)
  if [ -n "$BUILD_SCRIPT" ]; then
    add_full_script build "$BUILD_SCRIPT"
  else
    BUILD_SCRIPT=$(matching_package_scripts '^build:' | head -1)
    add_full_script build "$BUILD_SCRIPT"
  fi

  TEST_SCRIPT=$(first_package_script test || true)
  if [ -n "$TEST_SCRIPT" ]; then
    add_full_script test "$TEST_SCRIPT"
  else
    while IFS= read -r script_name; do
      add_full_script test "$script_name"
    done < <(matching_package_scripts '^test:')
  fi

  if [ "$FLAVOR" = "mini" ]; then
    while IFS= read -r script_name; do
      add_full_script smoke "$script_name"
    done < <(matching_package_scripts '(^|:)smoke(:|$)|^smoke')
  fi

  {
    echo "# full profile：先执行 verify.cmd，再按顺序执行本文件；一行一个命令"
    echo "# 只记录 package.json 中真实存在的脚本；缺失类别保持注释，不推断命令"
    if [ "$FULL_SCRIPT_COUNT" -gt 0 ]; then
      for script_name in "${FULL_SCRIPTS[@]}"; do
        echo "pnpm run $script_name"
      done
    fi
    [ "$LINT_FOUND" -eq 1 ] || echo "# lint: 未探测到可用脚本"
    [ "$BUILD_FOUND" -eq 1 ] || echo "# build: 未探测到可用脚本"
    [ "$TEST_FOUND" -eq 1 ] || echo "# test: 未探测到可用脚本（不生成 pnpm test）"
    if [ "$FLAVOR" = "mini" ] && [ "$SMOKE_FOUND" -ne 1 ]; then
      echo "# smoke: 未探测到平台 smoke 脚本"
    fi
  } > "$SPECS/verify.full.cmd"
  echo "✅ 写入 $SPECS/verify.full.cmd（$FULL_SCRIPT_COUNT 条深度检查，请人工确认）"
fi

# 5. 放一份填充指引供任意 agent 参考
cp "$DIR/RULE.md" "$SPECS/_RULE.md"

cat <<'EOF'

── 脚手架完成。下一步「填充」需要 agent / 人来做（脚本不替代）──
  1. 按 docs/specs/_RULE.md 与 spec-templates/SCHEMA.md，探索真实代码取证
  2. 逐份替换 docs/specs/ 里的 <填写：…> 占位符；务必校准 docs/specs/dangerous-zones.txt
  3. 人工核对 verify.cmd（fast）与 verify.full.cmd（可选 full），不要保留不存在的命令
  4. PC 项目如存在 docs/token-specs/，后续色号、字号以该目录 token 为准
  5. 复核后删除 docs/specs/_RULE.md，把各文档 frontmatter 的 status 改 active

  • Claude Code：直接运行 /init-specs，agent 会自动完成探索+填充
  • Codex / Cursor / Windsurf：先跑本脚本，再让 agent「按 docs/specs/_RULE.md 填充 docs/specs 占位符」
EOF
