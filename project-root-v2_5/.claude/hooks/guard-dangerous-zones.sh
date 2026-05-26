#!/bin/bash
# PreToolUse hook: 拦截对危险区文件的写入
# Exit 0 = 放行, Exit 2 = 阻止

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.file // empty')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# === 在下方添加你项目的真实危险区路径 ===
DANGEROUS_PATTERNS=(
  "src/shared/components/Base"
  "src/shared/components/Layout"
  "src/router/"
  "src/guards/"
  "src/interceptors/"
  "src/styles/global"
  "src/styles/theme"
  "src/config/"
  "vite.config"
  "tsconfig"
  ".env"
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if echo "$FILE_PATH" | grep -q "$pattern"; then
    echo "⛔ 危险区文件: $FILE_PATH" >&2
    echo "该文件属于公共基础设施，修改前请确认影响面。" >&2
    echo "参考 docs/specs/11_DANGEROUS_AREAS.md" >&2
    exit 2
  fi
done

exit 0
