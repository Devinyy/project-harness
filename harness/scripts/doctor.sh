#!/bin/bash
# 环境 / 完整性预检。两种模式：
#   - 自检模式 (self)    ：当前目录是 harness 包本身（有 spec-templates 且无 package.json）→ 检查 harness 自身是否健康
#   - 项目模式 (project) ：当前目录是接入了 harness 的业务项目根 → 检查环境 + specs 就绪度
# 自动判定，可用 --self / --project 强制。--strict：把"specs 未填/占位残留"从警告升级为失败（团队/CI 闸门）。
# SessionStart hook 与手动执行均可。

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd -P)
. "$SCRIPT_DIR/lib/specs-state.sh"

record_readiness() {
  local category="$1"
  local decision="$2"
  local exit_status="$3"
  [ -f "$SCRIPT_DIR/record-harness-event.sh" ] || return 0
  bash "$SCRIPT_DIR/record-harness-event.sh" \
    --adapter harness --event session_start --category "$category" \
    --decision "$decision" --exit "$exit_status" \
    >/dev/null 2>&1 || true
}

MODE=""; STRICT=0
for arg in "$@"; do
  case "$arg" in
    --self) MODE=self ;;
    --project) MODE=project ;;
    --strict) STRICT=1 ;;
  esac
done
if [ -z "$MODE" ]; then
  if [ -d "spec-templates" ] && [ ! -f "package.json" ]; then MODE=self; else MODE=project; fi
fi

ERRORS=0
warn(){ echo "⚠️ $*"; }
err(){ echo "❌ $*"; ERRORS=$((ERRORS+1)); }
have(){ command -v "$1" >/dev/null 2>&1; }

if [ "$MODE" = "self" ]; then
  echo "== Harness Doctor · 自检模式（检查 harness 包自身）=="

  for c in bash jq git; do have "$c" && echo "✅ $c" || warn "缺少 $c（hooks 运行需要）"; done

  # 机制层
  for f in CLAUDE.md AGENTS.md README.md .claude/settings.json .codex/config.toml scripts/doctor.sh; do
    [ -f "$f" ] && echo "✅ $f" || err "缺少 $f"
  done
  for d in .claude/commands .claude/hooks .codex/hooks spec-templates; do
    [ -d "$d" ] && echo "✅ $d/" || err "缺少 $d/"
  done
  # 命令与 hooks
  for f in init-specs new-page debug refactor review tech-solution; do
    [ -f ".claude/commands/$f.md" ] && echo "✅ command: /$f" || err "缺少 .claude/commands/$f.md"
  done

  # 模版骨架完整性（两套 flavor 各需的关键文件）
  echo "✅ spec-templates/SCHEMA.md"; [ -f "spec-templates/SCHEMA.md" ] || err "缺少 spec-templates/SCHEMA.md"
  for flavor in pc-microapp miniprogram-uniapp; do
    base="spec-templates/$flavor"
    if [ -d "$base" ]; then
      for must in RULE.md 00_PROJECT_FACTS.md INDEX.md dangerous-zones.txt 11_DANGEROUS_AREAS.md; do
        [ -f "$base/$must" ] && : || err "$flavor 缺少 $must"
      done
      [ -d "$base/AGENTS" ] && : || warn "$flavor 缺少 AGENTS/ 目录级模版"
      echo "✅ flavor: $flavor ($(find "$base" -type f | wc -l | tr -d ' ') files)"
    else
      err "缺少 flavor 目录 $base"
    fi
  done

  # hooks 可执行 + 语法
  for hook in .claude/hooks/*.sh .codex/hooks/*.sh scripts/*.sh; do
    [ -f "$hook" ] || continue
    [ -x "$hook" ] || warn "$hook 缺执行权限（chmod +x $hook）"
    bash -n "$hook" 2>/dev/null || err "$hook 语法错误"
  done

  # harness 包本身不应内置真实 specs
  if [ -f "docs/specs/00_PROJECT_FACTS.md" ]; then
    warn "harness 包内出现 docs/specs/00_PROJECT_FACTS.md —— 真实 specs 不应随 harness 分发"
  fi
  [ -d "docs/specs" ] && warn "harness 包内存在 docs/specs/ 目录（建议删除，避免与项目语义混淆；以 00_PROJECT_FACTS.md 判定是否已初始化）"

  if [ $ERRORS -gt 0 ]; then
    record_readiness readiness_failed fail 1
    echo "== ❌ 自检未通过（$ERRORS 项缺失）=="
    exit 1
  fi
  echo "== ✅ harness 自身健康 =="; exit 0
fi

# ---------------- 项目模式 ----------------
echo "== Harness Doctor · 项目模式（检查业务项目）=="

for c in node pnpm jq git; do have "$c" && echo "✅ $c $(command -v "$c")" || { [ "$c" = pnpm ] && warn "缺少 pnpm" || err "缺少 $c"; }; done

[ -f "package.json" ] && echo "✅ package.json" || err "缺少 package.json（本模式假设在业务项目根；若在 harness 包内请用 --self）"
[ -f "tsconfig.json" ] && echo "✅ tsconfig.json" || warn "未检测到 tsconfig.json"

# 项目类型
if [ -f "src/pages.json" ] || grep -q 'ecm-welfare-app' package.json 2>/dev/null; then
  echo "🔎 项目：uni-app 多端类"
  [ -f "src/pages.json" ] && echo "✅ src/pages.json" || warn "未检测到 src/pages.json"
  [ -f "src/manifest.json" ] && echo "✅ src/manifest.json" || warn "未检测到 src/manifest.json"
elif [ -d "apps/micro-main" ] || grep -q 'dc-platform' package.json 2>/dev/null; then
  echo "🔎 项目：PC 微前端类"
  [ -d "apps/micro-main" ] && echo "✅ apps/micro-main/" || warn "未检测到 apps/micro-main/"
else
  warn "未识别项目类型，按通用模式继续"
fi

# 类型检查器（两类项目都用 vue-tsc）
[ -x "node_modules/.bin/vue-tsc" ] && echo "✅ vue-tsc" || warn "未检测到 vue-tsc（类型检查 hook 会失败：pnpm add -D vue-tsc）"

# harness 完整性
[ -f "CLAUDE.md" ] && echo "✅ CLAUDE.md" || warn "缺少 CLAUDE.md"
[ -f "AGENTS.md" ] && echo "✅ AGENTS.md" || warn "缺少 AGENTS.md"
[ -d ".claude/hooks" ] && echo "✅ .claude/hooks/" || warn "缺少 .claude/hooks/"
[ -d ".codex/hooks" ] && echo "✅ .codex/hooks/" || warn "缺少 .codex/hooks/"

# specs 就绪度 —— 统一使用 missing / draft / active 三态
# 默认 specs 未填只是警告（适合草稿期）；--strict 下升级为失败（适合团队/CI 强约束）
specs_gate() { if [ "$STRICT" -eq 1 ]; then err "$1"; else warn "$1"; fi; }
SPECS_STATE=$(specs_state ".")
if [ "$SPECS_STATE" = "active" ]; then
  echo "✅ specs state=active（项目事实已复核）"
  [ -f "docs/specs/dangerous-zones.txt" ] && echo "✅ docs/specs/dangerous-zones.txt（驱动危险区 hook）" || specs_gate "缺少 docs/specs/dangerous-zones.txt，危险区 hook 用通用兜底，建议补齐"
  [ -f "docs/specs/INDEX.md" ] && echo "✅ docs/specs/INDEX.md" || warn "缺少 docs/specs/INDEX.md"
elif [ "$SPECS_STATE" = "draft" ]; then
  specs_gate "specs state=draft（存在占位符、非 active 状态或 facts 未声明 active），继续填充并人工复核"
  [ -f "docs/specs/dangerous-zones.txt" ] && echo "✅ docs/specs/dangerous-zones.txt（草稿，需校准）" || specs_gate "缺少 docs/specs/dangerous-zones.txt，危险区 hook 将使用通用兜底"
  [ -f "docs/specs/INDEX.md" ] && echo "✅ docs/specs/INDEX.md（草稿）" || warn "缺少 docs/specs/INDEX.md"
  if grep -rl '<填写' docs/specs >/dev/null 2>&1; then
    n=$(grep -rl '<填写' docs/specs | wc -l | tr -d ' ')
    specs_gate "docs/specs 仍有 <填写：…> 占位符未填（$n 个文件），运行 /init-specs 或手动补齐"
  fi
  if grep -rlE '^status:\s*(draft|template)' docs/specs >/dev/null 2>&1; then
    specs_gate "docs/specs 仍有 status: draft/template 未复核的文档，复核后改 active"
  fi
else
  specs_gate "specs state=missing —— 运行 bash scripts/init-specs.sh（任意 agent）或 /init-specs（Claude Code）生成 docs/specs/"
fi

# hooks 执行权限
for hook in .claude/hooks/*.sh .codex/hooks/*.sh scripts/*.sh; do
  [ -f "$hook" ] && [ ! -x "$hook" ] && warn "$hook 缺执行权限：chmod +x $hook"
done

READINESS_CATEGORY=""
case "$SPECS_STATE" in
  missing|draft) READINESS_CATEGORY="specs_$SPECS_STATE" ;;
esac

if [ $ERRORS -gt 0 ]; then
  record_readiness "${READINESS_CATEGORY:-readiness_failed}" fail 1
  echo "== ❌ 检查未通过（$ERRORS 项关键缺失）=="
  exit 1
fi
if [ -n "$READINESS_CATEGORY" ]; then
  record_readiness "$READINESS_CATEGORY" warn 0
fi
echo "== ✅ 环境检查通过 =="; exit 0
