#!/bin/bash
# PostToolUse hook: 单个 .vue 文件超过阈值时提示按 05_COMPONENT_PATTERNS.md 拆分。
# advisory：只提示不回滚（exit 2 让 agent 看到并决定是否拆），与 check-box-sizing 同模式。
# 巨型页面/组件不利于阅读与复用：页面应只做编排，业务逻辑抽 composable，语义区块抽子组件。
THRESHOLD=500

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.file // empty')
[ -z "$FILE_PATH" ] && exit 0
echo "$FILE_PATH" | grep -qE '\.vue$' || exit 0
[ -f "$FILE_PATH" ] || exit 0

LINES=$(wc -l < "$FILE_PATH" | tr -d ' ')
if [ "${LINES:-0}" -gt "$THRESHOLD" ]; then
  echo "⚠️ 巨型文件（$LINES 行 > $THRESHOLD）：$FILE_PATH" >&2
  echo "页面/组件过大不利于阅读与复用，请按 docs/specs/05_COMPONENT_PATTERNS.md「拆分原则」拆分：" >&2
  echo "  • 语义区块(头部/筛选/列表/弹窗)各抽子组件  • v-for item 大块抽 XxxCard/XxxItem" >&2
  echo "  • 业务逻辑抽 useXxxPage composable，页面只做编排（取数+组合子组件）" >&2
  exit 2
fi
exit 0
