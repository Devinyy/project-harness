#!/bin/bash
# PreToolUse hook: 拦截危险区写入。Exit 0 放行 / 2 阻止
# 危险区来源：docs/specs/dangerous-zones.txt（/init-specs 按项目生成）；缺失时用通用兜底。
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.file // empty' 2>/dev/null)
[ -z "$FILE_PATH" ] && exit 0
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd -P)
ZONES_FILE="$REPO_ROOT/docs/specs/dangerous-zones.txt"
AUDIT_SCRIPT="$REPO_ROOT/scripts/record-harness-event.sh"

record_dangerous_zone() {
  [ -f "$AUDIT_SCRIPT" ] || return 0
  bash "$AUDIT_SCRIPT" \
    --adapter claude --event pre_tool_use --category dangerous_zone --decision block --exit 2 \
    >/dev/null 2>&1 || true
}

if [ -f "$ZONES_FILE" ]; then
  while IFS= read -r pattern; do
    [ -z "$pattern" ] && continue
    case "$pattern" in \#*) continue ;; esac
    if echo "$FILE_PATH" | grep -qF -- "$pattern"; then
      record_dangerous_zone
      echo "⛔ 危险区文件: $FILE_PATH" >&2
      echo "命中 $ZONES_FILE 规则：$pattern；修改前确认影响面，见 docs/specs/11_DANGEROUS_AREAS.md" >&2
      exit 2
    fi
  done < "$ZONES_FILE"
  exit 0
fi
FALLBACK=( "src/router" "src/permission" "src/guards" "src/interceptors" "src/utils/request" "src/utils/auth" \
  "src/main.ts" "src/App.vue" "pages.json" "manifest.json" "src/uni.scss" "src/components/basic/" \
  "apps/micro-main/src/" "packages/http-client/" "packages/micro-bridge/" "src/config/" "vite.config" "tsconfig" ".env" )
for pattern in "${FALLBACK[@]}"; do
  if echo "$FILE_PATH" | grep -qF -- "$pattern"; then
    record_dangerous_zone
    echo "⛔ 危险区文件(通用兜底): $FILE_PATH" >&2
    echo "未检测到 docs/specs/dangerous-zones.txt，建议 /init-specs 生成项目专属清单。" >&2
    exit 2
  fi
done
exit 0
