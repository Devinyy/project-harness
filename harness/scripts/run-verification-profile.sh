#!/bin/bash
set -u

PROFILE="${1:-fast}"
case "$PROFILE" in
  fast|full) shift ;;
  *)
    printf '用法: bash scripts/run-verification-profile.sh fast|full [--snapshot FILE|--compare FILE]\n' >&2
    exit 2
    ;;
esac

MODE="normal"
STATE_FILE=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --snapshot|--compare)
      [ -n "${2:-}" ] || {
        printf '❌ %s 需要文件路径\n' "$1" >&2
        exit 2
      }
      [ "$MODE" = "normal" ] || {
        printf '❌ --snapshot 与 --compare 不能同时使用\n' >&2
        exit 2
      }
      if [ "$1" = "--snapshot" ]; then
        MODE="snapshot"
      else
        MODE="compare"
      fi
      STATE_FILE="$2"
      shift 2
      ;;
    *)
      printf '未知参数: %s\n' "$1" >&2
      exit 2
      ;;
  esac
done

FAST_FILE="docs/specs/verify.cmd"
FULL_FILE="docs/specs/verify.full.cmd"
COMMANDS=()

load_commands() {
  local command_file="$1"
  local line

  [ -f "$command_file" ] || return 0
  while IFS= read -r line || [ -n "$line" ]; do
    if [[ "$line" =~ ^[[:space:]]*(#|$) ]]; then
      continue
    fi
    COMMANDS[${#COMMANDS[@]}]="$line"
  done < "$command_file"
}

if [ ! -f "$FAST_FILE" ]; then
  printf '❌ 缺少 %s\n' "$FAST_FILE" >&2
  exit 2
fi

load_commands "$FAST_FILE"
if [ "$PROFILE" = "full" ]; then
  load_commands "$FULL_FILE"
fi

if [ "${#COMMANDS[@]}" -eq 0 ]; then
  printf '❌ %s profile 没有可执行命令\n' "$PROFILE" >&2
  exit 2
fi

if [ "$MODE" = "snapshot" ]; then
  if ! : > "$STATE_FILE"; then
    printf '❌ 无法创建 baseline: %s\n' "$STATE_FILE" >&2
    exit 2
  fi
elif [ "$MODE" = "compare" ] && [ ! -f "$STATE_FILE" ]; then
  printf '❌ baseline 不存在: %s\n' "$STATE_FILE" >&2
  exit 2
fi

NEW_FAILURES=0
for command_name in "${COMMANDS[@]}"; do
  printf '▶ %s\n' "$command_name"
  bash -c "$command_name"
  command_exit=$?

  case "$MODE" in
    normal)
      if [ "$command_exit" -ne 0 ]; then
        printf '❌ 命令失败（exit=%s）: %s\n' "$command_exit" "$command_name" >&2
        exit "$command_exit"
      fi
      ;;
    snapshot)
      if ! jq -cn \
          --arg command "$command_name" \
          --argjson exit "$command_exit" \
          '{command: $command, exit: $exit}' >> "$STATE_FILE"; then
        printf '❌ 无法写入 baseline: %s\n' "$STATE_FILE" >&2
        exit 2
      fi
      ;;
    compare)
      baseline_exit=$(
        jq -sr \
          --arg command "$command_name" \
          'map(select(.command == $command)) | if length == 0 then "" else (last.exit | tostring) end' \
          "$STATE_FILE" 2>/dev/null
      )
      if [ "$command_exit" -ne 0 ]; then
        if [ -n "$baseline_exit" ] && [ "$baseline_exit" -ne 0 ]; then
          printf '⚠️ 历史失败（baseline=%s, current=%s）: %s\n' \
            "$baseline_exit" "$command_exit" "$command_name" >&2
        else
          printf '❌ 新增失败（baseline=%s, current=%s）: %s\n' \
            "${baseline_exit:-missing}" "$command_exit" "$command_name" >&2
          NEW_FAILURES=$((NEW_FAILURES + 1))
        fi
      elif [ -n "$baseline_exit" ] && [ "$baseline_exit" -ne 0 ]; then
        printf '✅ 历史失败已恢复: %s\n' "$command_name"
      fi
      ;;
  esac
done

if [ "$MODE" = "compare" ] && [ "$NEW_FAILURES" -ne 0 ]; then
  exit 1
fi

exit 0
