#!/bin/bash
# PostToolUse hook: 校验「设置了 padding 的样式块必须声明 box-sizing: border-box」
# 规范见 docs/specs/04_CODING_STANDARDS.md「样式」。
# uni-app/小程序 view 默认 content-box，padding 叠加到宽高上，配合 width:100%/flex:1 易溢出错位。
# advisory：写入后扫描该文件，发现违规块打印行号+选择器并 exit 2（提示 agent 补齐，不回滚写入）。
# 假设样式经 stylelint 格式化（一行至多一个 { 或 }），这对本仓库成立。
#
# 仅在 uni-app 项目启用——该规范源于此类项目；其它项目跳过。

INPUT=$(cat)

# 项目门禁：非 uni-app 项目（无 src/pages.json 且 package.json 不含 ecm-welfare-app）直接放行
if [ ! -f "src/pages.json" ] && ! grep -q 'ecm-welfare-app' package.json 2>/dev/null; then
  exit 0
fi

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.file // empty')

[ -z "$FILE_PATH" ] && exit 0
echo "$FILE_PATH" | grep -qE '\.(vue|scss|css)$' || exit 0
[ -f "$FILE_PATH" ] || exit 0

REPORT=$(awk '
  FNR == 1 { isvue = (FILENAME ~ /\.vue$/) }
  {
    raw = $0
    sub(/\/\/.*/, "", raw)                 # 去行内 // 注释
    if (isvue && raw ~ /<style/)  instyle = 1
    if (isvue && raw ~ /<\/style>/) { instyle = 0 }

    # 扫描范围：.scss/.css 全文；.vue 仅 <style> 内
    if (isvue && !instyle) next

    opened = (raw ~ /\{/)
    closed = (raw ~ /\}/)

    if (opened && !closed) {
      sel = raw; sub(/\{.*/, "", sel); gsub(/^[ \t]+|[ \t]+$/, "", sel)
      if (sel == "") sel = lastsel
      depth++
      selstack[depth] = sel; padstack[depth] = 0; boxstack[depth] = 0; linestack[depth] = NR
    } else if (closed && !opened) {
      if (depth > 0) {
        if (padstack[depth] && !boxstack[depth])
          printf("  L%-5s %s\n", linestack[depth], selstack[depth])
        depth--
      }
    } else if (depth > 0) {
      # 声明行：归属当前栈顶块（最内层）
      if (raw ~ /(^|[; \t])padding(-[a-zA-Z]+)?[ \t]*:/) padstack[depth] = 1
      if (raw ~ /box-sizing[ \t]*:/) boxstack[depth] = 1
    }

    # 记住最近一个“纯选择器行”（无 {}:; ），供选择器单独成行时回填
    t = raw; gsub(/[ \t]/, "", t)
    if (t != "" && t !~ /[{}:;]/) { s = raw; gsub(/^[ \t]+|[ \t]+$/, "", s); lastsel = s }
  }
' "$FILE_PATH")

if [ -n "$REPORT" ]; then
  echo "⚠️ box-sizing 规范（docs/specs/04_CODING_STANDARDS.md「样式」）：" >&2
  echo "以下样式块设置了 padding 但缺少 box-sizing: border-box，请补齐：" >&2
  echo "$REPORT" >&2
  echo "文件：$FILE_PATH" >&2
  exit 2
fi

exit 0
