#!/bin/bash
# Shared validation for the project-knowledge template manifest.
#
# Callers must provide the manifest path and the template root.  The function
# intentionally only reads the distribution; generation and doctor policy are
# kept in their owning scripts.

knowledge_manifest_error() {
  printf '❌ %s\n' "$*" >&2
}

knowledge_manifest_valid_relative() {
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

knowledge_manifest_source_ok() {
  local template_root="$1"
  local relative_path="$2"
  local current="$template_root"
  local component
  knowledge_manifest_valid_relative "$relative_path" || return 1
  [ -d "$template_root" ] || return 1
  [ ! -L "$template_root" ] || return 1
  local old_ifs="$IFS"
  IFS=/
  for component in $relative_path; do
    current="$current/$component"
    [ ! -L "$current" ] || { IFS="$old_ifs"; return 1; }
  done
  IFS="$old_ifs"
  [ -f "$template_root/$relative_path" ] || return 1
  [ -r "$template_root/$relative_path" ] || return 1
  return 0
}

knowledge_manifest_lower() {
  printf '%s' "$1" | LC_ALL=C tr '[:upper:]' '[:lower:]'
}

knowledge_manifest_validate() {
  local manifest_file="${1:-}"
  local template_root="${2:-}"
  local rows_file=""
  local keys_file=""
  local line=""
  local field_count=0
  local row_domain=""
  local row_path=""
  local row_kind=""
  local path_key=""
  local rows=0
  local invalid=0
  local old_ifs

  [ -n "$manifest_file" ] || { knowledge_manifest_error "manifest 路径为空"; return 1; }
  [ -n "$template_root" ] || { knowledge_manifest_error "模板根路径为空"; return 1; }
  [ -f "$manifest_file" ] || { knowledge_manifest_error "找不到模板清单：$manifest_file"; return 1; }
  [ ! -L "$manifest_file" ] || { knowledge_manifest_error "模板清单不能是符号链接：$manifest_file"; return 1; }
  [ -r "$manifest_file" ] || { knowledge_manifest_error "模板清单不可读：$manifest_file"; return 1; }
  [ -d "$template_root" ] || { knowledge_manifest_error "找不到模板分发目录：$template_root"; return 1; }
  [ ! -L "$template_root" ] || { knowledge_manifest_error "模板分发目录不能是符号链接：$template_root"; return 1; }

  # Distribution input is deliberately strict: all tools then observe the
  # same LF/no-BOM contract instead of silently disagreeing on row parsing.
  local first_bytes
  first_bytes=$(LC_ALL=C od -An -t x1 -N 3 "$manifest_file" 2>/dev/null | tr -d ' \n\t')
  case "$first_bytes" in
    efbbbf*) knowledge_manifest_error "模板清单含 UTF-8 BOM：$manifest_file"; return 1 ;;
  esac
  if LC_ALL=C grep -q $'\r' "$manifest_file" 2>/dev/null; then
    knowledge_manifest_error "模板清单必须使用 LF 行尾，发现 CR/CRLF：$manifest_file"
    return 1
  fi

  rows_file=$(mktemp "${TMPDIR:-/tmp}/knowledge-manifest-rows.XXXXXX") || {
    knowledge_manifest_error "无法创建 manifest 校验临时文件"
    return 1
  }
  keys_file=$(mktemp "${TMPDIR:-/tmp}/knowledge-manifest-keys.XXXXXX") || {
    rm -f "$rows_file"
    knowledge_manifest_error "无法创建 manifest 去重临时文件"
    return 1
  }

  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      ''|\#*) continue ;;
    esac
    field_count=$(printf '%s\n' "$line" | awk -F '\t' '{print NF}')
    if [ "$field_count" -ne 3 ]; then
      knowledge_manifest_error "模板清单必须是三列 Tab 分隔：$line"
      invalid=1
      continue
    fi
    row_domain=""
    row_path=""
    row_kind=""
    IFS=$'\t' read -r row_domain row_path row_kind <<EOF
$line
EOF
    case "$row_domain" in
      harness|requirements|design|docs|experience) ;;
      *) knowledge_manifest_error "模板清单 domain 无效：$row_domain"; invalid=1; continue ;;
    esac
    case "$row_kind" in
      static)
        knowledge_manifest_valid_relative "$row_path" || {
          knowledge_manifest_error "模板清单 static 路径不安全：$row_path"
          invalid=1
          continue
        }
        case "$row_path" in
          docs/specs/*|docs/token-specs/*)
            knowledge_manifest_error "模板清单不得写入前端 specs/token 目录：$row_path"
            invalid=1
            continue
            ;;
        esac
        case "$row_domain:$row_path" in
          harness:harness/*|requirements:requirements/*|design:design/*|docs:docs/*|experience:experience/*|experience:badcase/*) ;;
          *)
            knowledge_manifest_error "模板清单 domain 与 path 不匹配：$row_domain -> $row_path"
            invalid=1
            continue
            ;;
        esac
        case "$(knowledge_manifest_lower "$row_path")" in
          requirements/modules/_module.md|badcase/_case.md)
            knowledge_manifest_error "动态模板不能标记为 static：$row_path"
            invalid=1
            continue
            ;;
        esac
        ;;
      module)
        if [ "$row_domain" != "requirements" ] || [ "$row_path" != "requirements/modules/_module.md" ]; then
          knowledge_manifest_error "module 源必须固定为 requirements/modules/_module.md：$row_path"
          invalid=1
          continue
        fi
        ;;
      case)
        if [ "$row_domain" != "experience" ] || [ "$row_path" != "badcase/_case.md" ]; then
          knowledge_manifest_error "case 源必须固定为 badcase/_case.md：$row_path"
          invalid=1
          continue
        fi
        ;;
      *) knowledge_manifest_error "模板清单 kind 无效：$row_kind"; invalid=1; continue ;;
    esac

    path_key=$(knowledge_manifest_lower "$row_path")
    if grep -F -x -q "$path_key" "$keys_file" 2>/dev/null; then
      knowledge_manifest_error "模板清单存在重复或大小写冲突路径：$row_path"
      invalid=1
      continue
    fi
    if ! printf '%s\n' "$path_key" >> "$keys_file"; then
      knowledge_manifest_error "manifest 去重计划写入失败"
      invalid=1
      continue
    fi
    if ! knowledge_manifest_source_ok "$template_root" "$row_path"; then
      if [ -L "$template_root/$row_path" ]; then
        knowledge_manifest_error "模板源路径不允许符号链接：$row_path"
      else
        knowledge_manifest_error "找不到模板源文件：$row_path"
      fi
      invalid=1
      continue
    fi
    if ! printf '%s\t%s\t%s\n' "$row_domain" "$row_path" "$row_kind" >> "$rows_file"; then
      knowledge_manifest_error "manifest 计划写入失败"
      invalid=1
      continue
    fi
    rows=$((rows + 1))
  done < "$manifest_file"

  old_ifs="$IFS"
  for row_domain in harness requirements design docs experience; do
    if ! awk -F '\t' -v domain="$row_domain" \
      '$1 == domain && $2 == domain "/MAP.md" && $3 == "static" { found = 1 } END { exit(found ? 0 : 1) }' \
      "$rows_file" >/dev/null 2>&1; then
      knowledge_manifest_error "domain 缺少固定 MAP 模板：$row_domain/MAP.md"
      invalid=1
    fi
  done
  IFS="$old_ifs"

  if [ "$rows" -eq 0 ]; then
    knowledge_manifest_error "模板清单为空或没有有效行：$manifest_file"
    invalid=1
  fi
  rm -f "$rows_file" "$keys_file"
  [ "$invalid" -eq 0 ]
}
