#!/bin/bash
# Explicitly materialize the optional project-knowledge templates.
#
# The script is intentionally independent from a target project's framework:
# templates are resolved relative to this script's distribution root while
# generated files are written to the caller's current working directory.
set -u

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd -P)
HARNESS_ROOT=$(cd "$SCRIPT_DIR/.." && pwd -P)
[ -f "$SCRIPT_DIR/lib/knowledge-manifest.sh" ] || { printf '❌ 缺少共享 manifest 校验器：%s\n' "$SCRIPT_DIR/lib/knowledge-manifest.sh" >&2; exit 1; }
. "$SCRIPT_DIR/lib/knowledge-manifest.sh"
TEMPLATE_ROOT="$HARNESS_ROOT/project-templates"
MANIFEST="$TEMPLATE_ROOT/MANIFEST.tsv"
OUTPUT_ROOT=$(pwd -P)
TARGET_ARG=""
PROJECT_MAP_FILE="PROJECT_MAP.md"

DOMAIN=""
MODULE=""
CASE_NAME=""
DRY_RUN=0
PLAN_FILE=""
LEGACY_FILE=""

usage() {
  cat <<'USAGE'
用法：
  bash scripts/init-project-knowledge.sh --domain <harness|requirements|design|docs|experience|all> [选项]

选项：
  --module <name>  在 requirements/modules/ 中实例化一个模块（需 --domain requirements 或 all）
  --case <name>    在 badcase/ 中实例化一个案例（需 --domain experience 或 all）
  --target <dir>   写入已存在的目标目录；省略时使用当前目录
  --dry-run        只显示将要生成/登记的内容，不创建文件或目录
  -h, --help       显示此帮助

不带参数只显示帮助，不会生成任何资料。生成物初始为 status: draft；已有文件不会覆盖。
USAGE
}

error() {
  printf '❌ %s\n' "$*"
}

die() {
  error "$1"
  exit "${2:-1}"
}

cleanup() {
  if [ -n "$PLAN_FILE" ] && [ -f "$PLAN_FILE" ]; then
    rm -f "$PLAN_FILE"
  fi
  if [ -n "$LEGACY_FILE" ] && [ -f "$LEGACY_FILE" ]; then
    rm -f "$LEGACY_FILE"
  fi
}

trap cleanup EXIT

if [ "$#" -eq 0 ]; then
  usage
  exit 0
fi

while [ "$#" -gt 0 ]; do
  case "$1" in
    --domain)
      [ "$#" -ge 2 ] || die "--domain 缺少参数值；请指定 domain" 2
      case "$2" in
        -*) die "--domain 缺少参数值；请指定 domain" 2 ;;
      esac
      [ -n "$2" ] || die "--domain 参数值不能为空" 2
      [ -z "$DOMAIN" ] || die "--domain 只能指定一次" 2
      DOMAIN="$2"
      shift 2
      ;;
    --module)
      [ "$#" -ge 2 ] || die "--module 缺少参数值；请指定模块名" 2
      case "$2" in
        -*) die "--module 缺少参数值；请指定模块名" 2 ;;
      esac
      [ -n "$2" ] || die "--module 参数值不能为空" 2
      [ -z "$MODULE" ] || die "--module 只能指定一次" 2
      MODULE="$2"
      shift 2
      ;;
    --case)
      [ "$#" -ge 2 ] || die "--case 缺少参数值；请指定案例名" 2
      case "$2" in
        -*) die "--case 缺少参数值；请指定案例名" 2 ;;
      esac
      [ -n "$2" ] || die "--case 参数值不能为空" 2
      [ -z "$CASE_NAME" ] || die "--case 只能指定一次" 2
      CASE_NAME="$2"
      shift 2
      ;;
    --target)
      [ "$#" -ge 2 ] || die "--target 缺少参数值；请指定已存在的目标目录" 2
      [ -n "$2" ] || die "--target 参数值不能为空" 2
      [ -z "$TARGET_ARG" ] || die "--target 只能指定一次" 2
      TARGET_ARG="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "未知参数：$1；请使用 --help 查看用法" 2
      ;;
  esac
done

if [ -n "$TARGET_ARG" ]; then
  case "$TARGET_ARG" in
    -*) die "--target 缺少有效目录参数" 2 ;;
  esac
  target_probe_base=$(pwd -P) || die "无法解析 --target 的当前目录" 2
  case "$TARGET_ARG" in
    /*) target_probe="$TARGET_ARG" ;;
    *) target_probe="$target_probe_base/$TARGET_ARG" ;;
  esac
  target_probe_current="/"
  target_probe_ifs="$IFS"
  IFS=/
  for target_probe_component in $target_probe; do
    case "$target_probe_component" in
      ''|.) continue ;;
      ..)
        target_probe_current="${target_probe_current%/*}"
        [ -n "$target_probe_current" ] || target_probe_current="/"
        ;;
      *)
        if [ "$target_probe_current" = "/" ]; then
          target_probe_next="/$target_probe_component"
        else
          target_probe_next="$target_probe_current/$target_probe_component"
        fi
        [ ! -L "$target_probe_next" ] || die "--target 路径包含符号链接组件：$target_probe_component" 2
        target_probe_current="$target_probe_next"
        ;;
    esac
  done
  IFS="$target_probe_ifs"
  [ -d "$TARGET_ARG" ] || die "目标目录不存在或不是目录：$TARGET_ARG" 2
  [ ! -L "$TARGET_ARG" ] || die "目标目录不能是符号链接：$TARGET_ARG" 2
  OUTPUT_ROOT=$(cd "$TARGET_ARG" && pwd -P) || die "无法解析目标目录：$TARGET_ARG" 2
else
  OUTPUT_ROOT=$(pwd -P) || die "无法解析当前工作目录" 2
fi

# Running without an explicit target from this repository's own checkout is a
# common accidental write.  Identify the source checkout by its fixed
# repository layout and tracked source paths: a normal installed package may
# itself be the root of a business Git repository and may contain a user's
# docs/superpowers directory, so those generic markers are not sufficient.
DEVELOPMENT_REPO_ROOT=$(git -C "$HARNESS_ROOT" rev-parse --show-toplevel 2>/dev/null || true)
DEVELOPMENT_CHECKOUT=0
if [ -n "$DEVELOPMENT_REPO_ROOT" ] &&
  [ "$HARNESS_ROOT" = "$DEVELOPMENT_REPO_ROOT/harness" ] &&
  [ -d "$HARNESS_ROOT/project-templates" ] && [ -d "$HARNESS_ROOT/docs/superpowers" ] &&
  git -C "$DEVELOPMENT_REPO_ROOT" ls-files --error-unmatch \
    harness/scripts/init-project-knowledge.sh \
    harness/scripts/doctor.sh \
    harness/project-templates/MANIFEST.tsv >/dev/null 2>&1; then
  DEVELOPMENT_CHECKOUT=1
fi
if [ -z "$TARGET_ARG" ] && [ "$DEVELOPMENT_CHECKOUT" -eq 1 ]; then
  case "$OUTPUT_ROOT" in
    "$DEVELOPMENT_REPO_ROOT"|"$DEVELOPMENT_REPO_ROOT"/*)
      die "拒绝在 Harness 开发 checkout 中隐式生成资料；请使用 --target 指定业务项目目录" 2
      ;;
  esac
fi

[ -n "$DOMAIN" ] || die "缺少 --domain；请使用 --help 查看用法" 2
case "$DOMAIN" in
  harness|requirements|design|docs|experience|all) ;;
  *) die "未知 domain：$DOMAIN；可选 harness、requirements、design、docs、experience、all" 2 ;;
esac

# Names are identifiers, not paths. Keep the accepted alphabet deliberately
# small so shell metacharacters, controls and traversal syntax never reach a
# target path or a renderer command.
valid_name() {
  local value="$1"
  local lower_value
  case "$value" in
    ''|.|..|/*|*/*|*\\*|*..*|*[!A-Za-z0-9._-]*) return 1 ;;
  esac
  lower_value=$(printf '%s' "$value" | LC_ALL=C tr '[:upper:]' '[:lower:]')
  case "$lower_value" in
    _module|_case|map|project_map) return 1 ;;
  esac
  return 0
}

valid_relative_path() {
  local value="$1"
  local component
  case "$value" in
    ''|/*|*\\*|*[![:print:]]*) return 1 ;;
  esac
  local old_ifs="$IFS"
  IFS=/
  for component in $value; do
    case "$component" in
      ''|.|..) IFS="$old_ifs"; return 1 ;;
    esac
  done
  IFS="$old_ifs"
  return 0
}

if [ -n "$MODULE" ]; then
  valid_name "$MODULE" || die "非法或保留 module 名称：$MODULE（不能包含绝对路径、斜杠、..、控制字符或 MAP/PROJECT_MAP/_module/_case）" 2
  case "$DOMAIN" in
    requirements|all) ;;
    *) die "--module 只能与 --domain requirements 或 all 一起使用" 2 ;;
  esac
fi

if [ -n "$CASE_NAME" ]; then
  valid_name "$CASE_NAME" || die "非法或保留 case 名称：$CASE_NAME（不能包含绝对路径、斜杠、..、控制字符或 MAP/PROJECT_MAP/_module/_case）" 2
  case "$DOMAIN" in
    experience|all) ;;
    *) die "--case 只能与 --domain experience 或 all 一起使用" 2 ;;
  esac
fi

[ -d "$TEMPLATE_ROOT" ] || die "找不到模板分发目录：$TEMPLATE_ROOT" 1
[ ! -L "$TEMPLATE_ROOT" ] || die "模板分发目录不能是符号链接：$TEMPLATE_ROOT" 1
[ -f "$MANIFEST" ] || die "找不到模板清单：$MANIFEST" 1
[ ! -L "$MANIFEST" ] || die "模板清单不能是符号链接：$MANIFEST" 1
[ -r "$MANIFEST" ] || die "模板清单不可读：$MANIFEST" 1

knowledge_manifest_validate "$MANIFEST" "$TEMPLATE_ROOT" || die "模板清单校验失败，未写入任何目标文件" 1

PLAN_FILE=$(mktemp "${TMPDIR:-/tmp}/harness-project-knowledge-plan.XXXXXX") || die "无法创建临时计划文件" 1

manifest_error=0
manifest_rows=0
module_row_found=0
case_row_found=0

append_plan() {
  local target_rel="$1"
  local source_rel="$2"
  local kind="$3"
  local plan_domain="$4"
  local existing_target
  while IFS=$'\t' read -r existing_target _ _ _; do
    [ "$existing_target" = "$target_rel" ] && die "模板清单产生重复目标路径：$target_rel" 1
  done < "$PLAN_FILE"
  if ! printf '%s\t%s\t%s\t%s\n' "$target_rel" "$source_rel" "$kind" "$plan_domain" >> "$PLAN_FILE"; then
    die "模板生成计划文件写入失败：$PLAN_FILE" 1
  fi
}

validate_manifest_row() {
  local row_domain="$1"
  local row_path="$2"
  local row_kind="$3"
  case "$row_domain" in
    harness|requirements|design|docs|experience) ;;
    *) error "模板清单 domain 无效：$row_domain"; return 1 ;;
  esac
  case "$row_kind" in
    static)
      valid_relative_path "$row_path" || { error "模板清单 static 路径不安全：$row_path"; return 1; }
      case "$row_path" in
        requirements/modules/_module.md|badcase/_case.md)
          error "动态模板不能标记为 static：$row_path"
          return 1
          ;;
      esac
      ;;
    module)
      [ "$row_domain" = "requirements" ] || { error "module 行必须属于 requirements：$row_path"; return 1; }
      [ "$row_path" = "requirements/modules/_module.md" ] || { error "module 源路径必须固定为 requirements/modules/_module.md：$row_path"; return 1; }
      ;;
    case)
      [ "$row_domain" = "experience" ] || { error "case 行必须属于 experience：$row_path"; return 1; }
      [ "$row_path" = "badcase/_case.md" ] || { error "case 源路径必须固定为 badcase/_case.md：$row_path"; return 1; }
      ;;
    *) error "模板清单 kind 无效：$row_kind"; return 1 ;;
  esac
  return 0
}

selected_domain() {
  local candidate="$1"
  if [ "$DOMAIN" = "all" ] || [ "$DOMAIN" = "$candidate" ]; then
    return 0
  fi
  return 1
}

# Validate the complete manifest before selecting any rows. This catches a
# broken distribution deterministically and keeps generation all-or-nothing.
while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in
    ''|\#*) continue ;;
  esac
  field_count=$(printf '%s\n' "$line" | awk -F '\t' '{print NF}')
  if [ "$field_count" -ne 3 ]; then
    error "模板清单必须是三列 Tab 分隔：$line"
    manifest_error=1
    continue
  fi
  row_domain=""
  row_path=""
  row_kind=""
  IFS=$'\t' read -r row_domain row_path row_kind <<EOF
$line
EOF
  if ! validate_manifest_row "$row_domain" "$row_path" "$row_kind"; then
    manifest_error=1
    continue
  fi
  manifest_rows=$((manifest_rows + 1))

  if [ "$row_domain" = "requirements" ] && [ "$row_kind" = "module" ]; then
    module_row_found=1
  fi
  if [ "$row_domain" = "experience" ] && [ "$row_kind" = "case" ]; then
    case_row_found=1
  fi

  if selected_domain "$row_domain" && [ "$row_kind" = "static" ]; then
    append_plan "$row_path" "$row_path" static "$row_domain"
  fi
done < "$MANIFEST"

[ "$manifest_error" -eq 0 ] || die "模板清单校验失败，未写入任何目标文件" 1
[ "$manifest_rows" -gt 0 ] || die "模板清单为空，未写入任何目标文件" 1

if [ -n "$MODULE" ]; then
  [ "$module_row_found" -eq 1 ] || die "模板清单缺少 requirements/modules/_module.md module 模板" 1
  append_plan "requirements/modules/$MODULE.md" "requirements/modules/_module.md" module requirements
fi
if [ -n "$CASE_NAME" ]; then
  [ "$case_row_found" -eq 1 ] || die "模板清单缺少 badcase/_case.md case 模板" 1
  append_plan "badcase/$CASE_NAME.md" "badcase/_case.md" case experience
fi

plan_has_target() {
  local wanted="$1"
  local planned_target
  while IFS=$'\t' read -r planned_target _ _ _; do
    [ "$planned_target" = "$wanted" ] && return 0
  done < "$PLAN_FILE"
  return 1
}

validate_source() {
  local relative_path="$1"
  local current="$TEMPLATE_ROOT"
  local component
  valid_relative_path "$relative_path" || { error "模板源路径不安全：$relative_path"; return 1; }
  local old_ifs="$IFS"
  IFS=/
  for component in $relative_path; do
    current="$current/$component"
    if [ -L "$current" ]; then
      error "模板源路径不允许符号链接逃逸：$relative_path"
      IFS="$old_ifs"
      return 1
    fi
  done
  IFS="$old_ifs"
  [ -f "$TEMPLATE_ROOT/$relative_path" ] || { error "找不到模板源文件：$relative_path"; return 1; }
  [ -r "$TEMPLATE_ROOT/$relative_path" ] || { error "模板源文件不可读：$relative_path"; return 1; }
  return 0
}

validate_target() {
  local relative_path="$1"
  local current="$OUTPUT_ROOT"
  local component
  local next_path
  local sibling
  local sibling_name
  local component_key
  local sibling_key
  local is_last=0
  local old_ifs
  valid_relative_path "$relative_path" || { error "目标路径不安全：$relative_path"; return 1; }
  [ -d "$OUTPUT_ROOT" ] || { error "目标根不是目录：$OUTPUT_ROOT"; return 1; }
  [ -r "$OUTPUT_ROOT" ] && [ -x "$OUTPUT_ROOT" ] || { error "目标根缺少读取/遍历权限：$OUTPUT_ROOT"; return 1; }
  old_ifs="$IFS"
  IFS=/
  for component in $relative_path; do
    next_path="$current/$component"
    [ "$next_path" = "$OUTPUT_ROOT/$relative_path" ] && is_last=1 || is_last=0
    component_key=$(knowledge_manifest_lower "$component")

    # Detect case collisions even on a case-sensitive CI filesystem; on a
    # case-insensitive distribution the same collision would otherwise be an
    # implicit overwrite.
    if [ -d "$current" ]; then
      while IFS= read -r sibling; do
        [ -e "$sibling" ] || [ -L "$sibling" ] || continue
        sibling_name="${sibling##*/}"
        sibling_key=$(knowledge_manifest_lower "$sibling_name")
        if [ "$sibling_key" = "$component_key" ] && [ "$sibling_name" != "$component" ]; then
          error "目标路径存在大小写冲突：$relative_path（已有 $sibling_name）"
          IFS="$old_ifs"
          return 1
        fi
      done < <(find "$current" -maxdepth 1 -mindepth 1 -print 2>/dev/null)
    fi

    if [ -L "$next_path" ]; then
      error "目标路径存在符号链接逃逸风险：$relative_path"
      IFS="$old_ifs"
      return 1
    fi
    if [ -e "$next_path" ]; then
      if [ "$is_last" -eq 1 ]; then
        if [ ! -f "$next_path" ]; then
          error "目标路径已存在但不是普通文件：$relative_path"
          IFS="$old_ifs"
          return 1
        fi
        case "$component" in
          MAP.md|PROJECT_MAP.md)
            [ -w "$next_path" ] || {
              error "索引目标缺少写权限：$relative_path"
              IFS="$old_ifs"
              return 1
            }
            ;;
        esac
      else
        if [ ! -d "$next_path" ]; then
          error "目标路径中间组件是普通文件而非目录：$relative_path"
          IFS="$old_ifs"
          return 1
        fi
        [ -r "$next_path" ] && [ -x "$next_path" ] || {
          error "目标父目录缺少读取/遍历权限：$next_path"
          IFS="$old_ifs"
          return 1
        }
        [ -w "$next_path" ] || {
          error "目标父目录缺少写权限：$next_path"
          IFS="$old_ifs"
          return 1
        }
      fi
    else
      if [ -d "$current" ]; then
        [ -w "$current" ] && [ -x "$current" ] || {
          error "目标父目录缺少写权限：$current"
          IFS="$old_ifs"
          return 1
        }
      fi
    fi
    current="$next_path"
  done
  IFS="$old_ifs"
  return 0
}

# A generated domain must have a domain MAP in the selected static set; this
# prevents root navigation from pointing at a path the invocation did not
# actually materialize.
case "$DOMAIN" in
  all)
    selected_domains="harness requirements design docs experience"
    ;;
  *)
    selected_domains="$DOMAIN"
    ;;
esac
for selected in $selected_domains; do
  plan_has_target "$selected/MAP.md" || die "domain $selected 缺少静态 MAP.md 模板，拒绝生成坏链接" 1
done
if [ -n "$MODULE" ]; then
  plan_has_target "requirements/modules/MAP.md" || die "requirements 缺少 modules/MAP.md，无法登记模块" 1
fi
if [ -n "$CASE_NAME" ]; then
  plan_has_target "badcase/MAP.md" || die "experience 缺少 badcase/MAP.md，无法登记案例" 1
fi

source_error=0
target_error=0
target_rel=""
source_rel=""
while IFS=$'\t' read -r target_rel source_rel _ _; do
  validate_source "$source_rel" || source_error=1
  validate_target "$target_rel" || target_error=1
done < "$PLAN_FILE"

# Root and local MAP files are also targets. Validate them before creating any
# directory so a broken or symlinked navigation tree cannot receive a partial
# write.
validate_target "$PROJECT_MAP_FILE" || target_error=1
if [ -n "$MODULE" ]; then
  validate_target "requirements/MAP.md" || target_error=1
  validate_target "requirements/modules/MAP.md" || target_error=1
fi
if [ -n "$CASE_NAME" ]; then
  validate_target "experience/MAP.md" || target_error=1
  validate_target "badcase/MAP.md" || target_error=1
fi
[ "$source_error" -eq 0 ] || die "模板源校验失败，未写入任何目标文件" 1
[ "$target_error" -eq 0 ] || die "目标路径校验失败，未写入任何目标文件" 1

collect_legacy_map_entries() {
  local legacy_map="$OUTPUT_ROOT/MAP.md"
  local line=""
  local link=""
  local label=""
  local target_path=""
  local in_block=0
  [ -f "$legacy_map" ] || return 0
  grep -F -q '<!-- init-project-knowledge generated entries -->' "$legacy_map" 2>/dev/null || return 0
  LEGACY_FILE=$(mktemp "${TMPDIR:-/tmp}/harness-project-knowledge-legacy.XXXXXX") || {
    die "无法创建旧 MAP 迁移计划文件" 1
  }
  while IFS= read -r line || [ -n "$line" ]; do
    if [ "$line" = '<!-- init-project-knowledge generated entries -->' ]; then
      in_block=1
      continue
    fi
    [ "$in_block" -eq 1 ] || continue
    case "$line" in
      *']('*')'*) ;;
      *)
        case "$line" in
          '- ['*)
            error "旧 MAP 迁移候选不是有效本地 Markdown 链接：$line"
            return 1
            ;;
        esac
        continue
        ;;
    esac
    link=$(printf '%s\n' "$line" | sed -nE 's/.*\]\(([^)]*)\).*/\1/p')
    label=$(printf '%s\n' "$line" | sed -nE 's/.*\[([^]]*)\]\([^)]*\).*/\1/p')
    [ -n "$link" ] && [ -n "$label" ] || {
      error "旧 MAP 迁移候选链接格式无效：$line"
      return 1
    }
    case "$link" in
      ./*) ;;
      *) error "旧 MAP 迁移候选必须是根相对本地链接：$link"; return 1 ;;
    esac
    target_path="${link#./}"
    target_path="${target_path%%#*}"
    valid_relative_path "$target_path" || {
      error "旧 MAP 迁移候选路径不安全：$link"
      return 1
    }
    if ! plan_has_target "$target_path" && [ ! -f "$OUTPUT_ROOT/$target_path" ]; then
      error "旧 MAP 迁移候选目标不存在：$link"
      return 1
    fi
    validate_target "$target_path" || return 1
    if ! printf '%s\t%s\n' "$label" "$link" >> "$LEGACY_FILE"; then
      error "旧 MAP 迁移计划写入失败"
      return 1
    fi
  done < "$legacy_map"
  return 0
}

collect_legacy_map_entries || die "旧 MAP 迁移预检失败，未写入任何目标文件" 1

utc_date=$(LC_ALL=C date -u +%Y-%m-%d) || die "无法取得 UTC 日期" 1

root_marker_for() {
  local relative_path="$1"
  local directory
  local marker=""
  local component
  case "$relative_path" in
    */*)
      directory="${relative_path%/*}"
      local old_ifs="$IFS"
      IFS=/
      for component in $directory; do
        marker="../$marker"
      done
      IFS="$old_ifs"
      printf '%s' "$marker"
      ;;
    *) printf './' ;;
  esac
}

render_template() {
  local target_rel="$1"
  local source_rel="$2"
  local target="$OUTPUT_ROOT/$target_rel"
  local source="$TEMPLATE_ROOT/$source_rel"
  local target_dir
  local temp_file
  local root_marker
  root_marker=$(root_marker_for "$target_rel")

  if [ -e "$target" ]; then
    printf '↷ 已存在，跳过 %s\n' "$target_rel"
    return 0
  fi
  target_dir=$(dirname "$target")
  mkdir -p "$target_dir" || { error "无法创建目标目录：$target_dir"; return 1; }
  temp_file=$(mktemp "$target_dir/.harness-project-knowledge.XXXXXX") || {
    error "无法创建临时生成文件：$target_rel"
    return 1
  }
  if ! sed \
    -e "s|{{ROOT}}|$root_marker|g" \
    -e "s|{{MODULE}}|$MODULE|g" \
    -e "s|{{CASE}}|$CASE_NAME|g" \
    -e "s|{{DATE}}|$utc_date|g" \
    -e 's/^status:[[:space:]]*template[[:space:]]*$/status: draft/' \
    "$source" > "$temp_file"; then
    rm -f "$temp_file"
    error "渲染模板失败：$source_rel"
    return 1
  fi
  if [ -e "$target" ] || [ -L "$target" ]; then
    rm -f "$temp_file"
    if [ -L "$target" ]; then
      error "目标在写入前变为符号链接：$target_rel"
      return 1
    fi
    printf '↷ 已存在，跳过 %s\n' "$target_rel"
    return 0
  fi
  mv "$temp_file" "$target" || {
    rm -f "$temp_file"
    error "无法写入目标文件：$target_rel"
    return 1
  }
  printf '✅ 生成 %s\n' "$target_rel"
  return 0
}

if [ "$DRY_RUN" -eq 1 ]; then
  while IFS=$'\t' read -r target_rel source_rel _ _; do
    printf 'DRY-RUN 生成 %s（源 %s）\n' "$target_rel" "$source_rel"
  done < "$PLAN_FILE"
  printf 'DRY-RUN 登记项目 MAP：%s\n' "$OUTPUT_ROOT/$PROJECT_MAP_FILE"
  [ -n "$MODULE" ] && printf 'DRY-RUN 登记模块 MAP：requirements/modules/%s.md\n' "$MODULE"
  [ -n "$CASE_NAME" ] && printf 'DRY-RUN 登记案例 MAP：badcase/%s.md\n' "$CASE_NAME"
  exit 0
fi

write_error=0
while IFS=$'\t' read -r target_rel source_rel _ _; do
  render_template "$target_rel" "$source_rel" || write_error=1
done < "$PLAN_FILE"
[ "$write_error" -eq 0 ] || die "模板生成失败；已生成的文件未覆盖，但请检查上述错误" 1

project_map="$OUTPUT_ROOT/$PROJECT_MAP_FILE"
if [ ! -e "$project_map" ]; then
  mkdir -p "$OUTPUT_ROOT" || die "无法准备目标根目录" 1
  {
    printf '%s\n' '---'
    printf '%s\n' 'status: draft'
    printf '%s\n' '---'
    printf '\n# 项目资料登记\n\n'
    printf '本入口只登记本次实际生成的资料域；未生成领域不在此伪造链接。\n'
  } > "$project_map" || die "无法创建项目资料登记 PROJECT_MAP.md" 1
fi

append_map_entry() {
  local map_rel="$1"
  local link="$2"
  local label="$3"
  local map_file="$OUTPUT_ROOT/$map_rel"
  local alternate_link
  local marker='<!-- init-project-knowledge generated entries -->'
  [ -f "$map_file" ] || { error "登记目标 MAP 不存在：$map_rel"; return 1; }
  if grep -F -q "]($link)" "$map_file" 2>/dev/null; then
    printf '↷ MAP 已登记 %s -> %s\n' "$map_rel" "$link"
    return 0
  fi
  case "$link" in
    ./*) alternate_link="${link#./}" ;;
    *) alternate_link="./$link" ;;
  esac
  if [ "$alternate_link" != "$link" ] && grep -F -q "]($alternate_link)" "$map_file" 2>/dev/null; then
    printf '↷ MAP 已登记 %s -> %s（等价路径）\n' "$map_rel" "$link"
    return 0
  fi
  if ! grep -F -q "$marker" "$map_file" 2>/dev/null; then
    printf '\n%s\n' "$marker" >> "$map_file" || return 1
  fi
  printf -- '- [%s](%s)\n' "$label" "$link" >> "$map_file" || return 1
  printf '✅ MAP 登记 %s -> %s\n' "$map_rel" "$link"
  return 0
}

nearest_map_for() {
  local target_rel="$1"
  local directory
  case "$target_rel" in
    */*) directory="${target_rel%/*}" ;;
    *) printf '%s' "$PROJECT_MAP_FILE"; return 0 ;;
  esac
  if [ "${target_rel##*/}" = "MAP.md" ]; then
    case "$directory" in
      */*) directory="${directory%/*}" ;;
      *) directory="" ;;
    esac
  fi
  while [ -n "$directory" ]; do
    if plan_has_target "$directory/MAP.md"; then
      printf '%s/MAP.md' "$directory"
      return 0
    fi
    case "$directory" in
      */*) directory="${directory%/*}" ;;
      *) directory="" ;;
    esac
  done
  printf '%s' "$PROJECT_MAP_FILE"
}

relative_link() {
  local map_rel="$1"
  local target_rel="$2"
  awk -v map_path="$map_rel" -v target_path="$target_rel" '
    BEGIN {
      map_count = split(map_path, map_parts, "/") - 1
      target_count = split(target_path, target_parts, "/")
      common = 1
      while (common <= map_count && common <= target_count && map_parts[common] == target_parts[common]) {
        common++
      }
      result = ""
      for (i = common; i <= map_count; i++) result = result "../"
      for (i = common; i <= target_count; i++) {
        if (i > common) result = result "/"
        result = result target_parts[i]
      }
      if (result !~ /^\.\.\//) result = "./" result
      print result
    }
  '
}

map_label_for() {
  local target_rel="$1"
  local basename="${target_rel##*/}"
  if [ "$basename" = "MAP.md" ]; then
    basename="${target_rel%/*}"
    basename="${basename##*/}"
    printf '%s' "$basename"
    return 0
  fi
  case "$basename" in
    *.md) printf '%s' "${basename%.md}" ;;
    *) printf '%s' "$basename" ;;
  esac
}

map_error=0
if [ -n "$LEGACY_FILE" ] && [ -s "$LEGACY_FILE" ]; then
  while IFS=$'\t' read -r legacy_label legacy_link; do
    append_map_entry "$PROJECT_MAP_FILE" "$legacy_link" "$legacy_label" || map_error=1
  done < "$LEGACY_FILE"
fi

for selected in $selected_domains; do
  append_map_entry "$PROJECT_MAP_FILE" "./$selected/MAP.md" "$selected" || map_error=1
done
if [ "$DOMAIN" = "all" ] || [ "$DOMAIN" = "experience" ]; then
  append_map_entry "$PROJECT_MAP_FILE" "./badcase/MAP.md" "badcase" || map_error=1
  append_map_entry "experience/MAP.md" "../badcase/MAP.md" "badcase" || map_error=1
fi

# Keep each newly materialized file reachable from the nearest MAP. Default
# templates already contain many of these links; append_map_entry recognizes
# both `foo.md` and `./foo.md` so custom or older MAPs are only supplemented.
while IFS=$'\t' read -r target_rel source_rel _ _; do
  case "${target_rel##*/}" in
    MAP.md)
      [ "$target_rel" = "MAP.md" ] && continue
      [ "$target_rel" = "badcase/MAP.md" ] && continue
      ;;
  esac
  nearest_map=$(nearest_map_for "$target_rel")
  nearest_link=$(relative_link "$nearest_map" "$target_rel")
  nearest_label=$(map_label_for "$target_rel")
  append_map_entry "$nearest_map" "$nearest_link" "$nearest_label" || map_error=1
done < "$PLAN_FILE"

if [ -n "$MODULE" ]; then
  append_map_entry "requirements/MAP.md" "./modules/MAP.md" "modules" || map_error=1
  append_map_entry "requirements/modules/MAP.md" "./$MODULE.md" "$MODULE" || map_error=1
fi
if [ -n "$CASE_NAME" ]; then
  append_map_entry "badcase/MAP.md" "./$CASE_NAME.md" "$CASE_NAME" || map_error=1
fi
[ "$map_error" -eq 0 ] || die "MAP 登记失败；已生成文件保持不覆盖语义，请检查目标权限" 1

printf '✅ project knowledge 初始化完成（status: draft）\n'
exit 0
