#!/bin/bash
set -u

TEST_DIR=$(cd "$(dirname "$0")" && pwd -P)
HARNESS_ROOT=$(cd "$TEST_DIR/../.." && pwd -P)
. "$TEST_DIR/testlib.sh"

FIXTURE_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/harness-claude-hooks.XXXXXX")
trap 'rm -rf "$FIXTURE_ROOT"' EXIT

git -C "$FIXTURE_ROOT" init -q
mkdir -p "$FIXTURE_ROOT/docs/specs" "$FIXTURE_ROOT/nested/deeper"
printf 'private-area/\n' > "$FIXTURE_ROOT/docs/specs/dangerous-zones.txt"

run_claude_hook() {
  local hook_path="$1"
  local input="$2"
  local output_file="$FIXTURE_ROOT/hook-output"
  local error_file="$FIXTURE_ROOT/hook-error"

  (
    cd "$FIXTURE_ROOT/nested/deeper" &&
      printf '%s' "$input" | bash "$hook_path"
  ) >"$output_file" 2>"$error_file"
  HOOK_EXIT=$?
  HOOK_OUTPUT=$(cat "$output_file")
  HOOK_ERROR=$(cat "$error_file")
}

BLOCK_HOOK="$HARNESS_ROOT/.claude/hooks/block-dangerous-commands.sh"
run_claude_hook "$BLOCK_HOOK" '{"tool_input":{"command":"git status"}}'
assert_eq "0" "$HOOK_EXIT" "Claude allows safe shell commands"

run_claude_hook "$BLOCK_HOOK" '{"tool_input":{"command":"git reset --hard HEAD"}}'
assert_eq "2" "$HOOK_EXIT" "Claude blocks dangerous shell commands"
assert_contains "$HOOK_ERROR" "危险命令" "Claude explains dangerous shell block"

run_claude_hook "$BLOCK_HOOK" '{malformed'
assert_eq "0" "$HOOK_EXIT" "Claude allows malformed hook input safely"

run_claude_hook "$BLOCK_HOOK" ''
assert_eq "0" "$HOOK_EXIT" "Claude allows empty hook input safely"

GUARD_HOOK="$HARNESS_ROOT/.claude/hooks/guard-dangerous-zones.sh"
run_claude_hook "$GUARD_HOOK" '{"tool_input":{"file_path":"src/views/Normal.vue"}}'
assert_eq "0" "$HOOK_EXIT" "Claude allows normal file edits"

run_claude_hook "$GUARD_HOOK" '{"tool_input":{"file_path":"private-area/config.ts"}}'
assert_eq "2" "$HOOK_EXIT" "Claude resolves project dangerous zones from nested directories"
assert_contains "$HOOK_ERROR" "private-area/" "Claude reports the matched project rule"

finish_tests
