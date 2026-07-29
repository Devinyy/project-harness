#!/bin/bash
set -u

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd -P)
HARNESS_ROOT=$(cd "$SCRIPT_DIR/.." && pwd -P)
. "$SCRIPT_DIR/lib/specs-state.sh"

MODE=""
case "${1:-}" in
  --self) MODE="self" ;;
  --project) MODE="project" ;;
  "") ;;
  *) printf '未知参数: %s\n' "$1" >&2; exit 2 ;;
esac

if [ -z "$MODE" ]; then
  if [ -d "$HARNESS_ROOT/spec-templates" ] && [ ! -f "$HARNESS_ROOT/package.json" ]; then
    MODE="self"
  else
    MODE="project"
  fi
fi

if [ "$MODE" = "self" ]; then
  HARNESS_SELF_VERIFY_CHILD=1 bash "$HARNESS_ROOT/tests/harness/run.sh"
  exit $?
fi

PROJECT_ROOT=$(pwd -P)
STATE=$(specs_state "$PROJECT_ROOT")
if [ "$STATE" != "active" ]; then
  printf '❌ specs state=%s：项目验证只接受已复核的 active specs\n' "$STATE" >&2
  exit 2
fi

resolve_project_verification() {
  local verify_file="$PROJECT_ROOT/docs/specs/verify.cmd"
  local script_name

  if [ -f "$verify_file" ]; then
    grep -vE '^[[:space:]]*(#|$)' "$verify_file" | head -1
    return
  fi

  if [ -f "$PROJECT_ROOT/package.json" ]; then
    for script_name in lint:type validate type-check typecheck check; do
      if jq -e --arg script_name "$script_name" '.scripts[$script_name] // empty' "$PROJECT_ROOT/package.json" >/dev/null 2>&1; then
        printf 'pnpm run %s\n' "$script_name"
        return
      fi
    done
  fi

  printf 'pnpm exec vue-tsc --noEmit\n'
}

VERIFY_COMMAND=$(resolve_project_verification)
if [ -z "$VERIFY_COMMAND" ]; then
  printf '❌ 未找到项目验证命令\n' >&2
  exit 2
fi

bash -c "$VERIFY_COMMAND"
