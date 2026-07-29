#!/bin/bash
set -u

ADAPTER="${1:-unknown}"
INPUT=$(cat)
HOOK_EVENT=$(printf '%s' "$INPUT" | jq -r '.hook_event_name // empty' 2>/dev/null)
PERMISSION_MODE=$(printf '%s' "$INPUT" | jq -r '.permission_mode // empty' 2>/dev/null)
TOOL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
[ "$HOOK_EVENT" = "PostToolUse" ] || exit 0

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd -P)
RECORDER="$SCRIPT_DIR/record-harness-event.sh"
[ -f "$RECORDER" ] || exit 0

CATEGORY=""
DECISION=""
case "$PERMISSION_MODE" in
  acceptEdits)
    case "$TOOL_NAME" in
      Write|Edit|MultiEdit|apply_patch)
        CATEGORY="explicit_approval"
        DECISION="approve"
        ;;
    esac
    ;;
  bypassPermissions)
    CATEGORY="explicit_bypass"
    DECISION="bypass"
    ;;
esac

[ -n "$CATEGORY" ] || exit 0
bash "$RECORDER" \
  --adapter "$ADAPTER" \
  --event post_tool_use \
  --category "$CATEGORY" \
  --decision "$DECISION" \
  --exit 0 \
  >/dev/null 2>&1 || true
exit 0
