#!/bin/bash
set -u

ADAPTER_VALUE="unknown"
EVENT_VALUE="unknown"
CATEGORY_VALUE="unknown"
DECISION_VALUE="unknown"
EXIT_VALUE="-1"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --adapter)
      [ "$#" -ge 2 ] || { shift; continue; }
      ADAPTER_VALUE="${2:-unknown}"
      shift 2
      ;;
    --event)
      [ "$#" -ge 2 ] || { shift; continue; }
      EVENT_VALUE="${2:-unknown}"
      shift 2
      ;;
    --category)
      [ "$#" -ge 2 ] || { shift; continue; }
      CATEGORY_VALUE="${2:-unknown}"
      shift 2
      ;;
    --decision)
      [ "$#" -ge 2 ] || { shift; continue; }
      DECISION_VALUE="${2:-unknown}"
      shift 2
      ;;
    --exit)
      [ "$#" -ge 2 ] || { shift; continue; }
      EXIT_VALUE="${2:--1}"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

normalize_adapter() {
  case "$1" in
    claude|codex|harness) printf '%s\n' "$1" ;;
    *) printf 'unknown\n' ;;
  esac
}

normalize_event() {
  case "$1" in
    pre_tool_use|post_tool_use|stop|readiness|approval|session_start) printf '%s\n' "$1" ;;
    *) printf 'unknown\n' ;;
  esac
}

normalize_category() {
  case "$1" in
    destructive_operation|dependency_install|network_egress|tool_policy|dangerous_zone|\
    verification_failed|readiness_failed|specs_missing|specs_draft|explicit_approval|explicit_bypass)
      printf '%s\n' "$1"
      ;;
    *) printf 'unknown\n' ;;
  esac
}

normalize_decision() {
  case "$1" in
    allow|block|warn|fail|approve|bypass) printf '%s\n' "$1" ;;
    *) printf 'unknown\n' ;;
  esac
}

ADAPTER=$(normalize_adapter "$ADAPTER_VALUE")
EVENT=$(normalize_event "$EVENT_VALUE")
CATEGORY=$(normalize_category "$CATEGORY_VALUE")
DECISION=$(normalize_decision "$DECISION_VALUE")
if printf '%s' "$EXIT_VALUE" | grep -qE '^-?[0-9]+$'; then
  EXIT_STATUS="$EXIT_VALUE"
else
  EXIT_STATUS=-1
fi

EVENTS_FILE=$(git rev-parse --git-path harness/events.jsonl 2>/dev/null) || exit 0
[ -n "$EVENTS_FILE" ] || exit 0
EVENTS_DIR=$(dirname "$EVENTS_FILE")
mkdir -p "$EVENTS_DIR" >/dev/null 2>&1 || exit 0

TIMESTAMP=$(date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || printf 'unknown')
EVENT_JSON=$(
  jq -cn \
    --arg timestamp "$TIMESTAMP" \
    --arg adapter "$ADAPTER" \
    --arg event "$EVENT" \
    --arg category "$CATEGORY" \
    --arg decision "$DECISION" \
    --argjson exit_status "$EXIT_STATUS" \
    '{
      timestamp: $timestamp,
      adapter: $adapter,
      event: $event,
      category: $category,
      decision: $decision,
      exit_status: $exit_status
    }' 2>/dev/null
) || exit 0

printf '%s\n' "$EVENT_JSON" >> "$EVENTS_FILE" 2>/dev/null || true
exit 0
