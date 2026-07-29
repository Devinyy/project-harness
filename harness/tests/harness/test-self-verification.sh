#!/bin/bash
set -u

TEST_DIR=$(cd "$(dirname "$0")" && pwd -P)
HARNESS_ROOT=$(cd "$TEST_DIR/../.." && pwd -P)
. "$TEST_DIR/testlib.sh"

if [ "${HARNESS_SELF_VERIFY_CHILD:-0}" = "1" ]; then
  pass "nested self-verification avoids recursion"
  finish_tests
  exit 0
fi

FIXTURE_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/harness-self-verification.XXXXXX")
trap 'rm -rf "$FIXTURE_ROOT"' EXIT
mkdir -p "$FIXTURE_ROOT/bin"

printf '%s\n' \
  '#!/bin/bash' \
  'printf invoked > "$PNPM_MARKER"' \
  'exit 88' > "$FIXTURE_ROOT/bin/pnpm"
chmod +x "$FIXTURE_ROOT/bin/pnpm"

VERIFY_SCRIPT="$HARNESS_ROOT/scripts/verify-harness.sh"
if [ -f "$VERIFY_SCRIPT" ]; then
  self_marker="$FIXTURE_ROOT/self-pnpm"
  PATH="$FIXTURE_ROOT/bin:$PATH" PNPM_MARKER="$self_marker" bash "$VERIFY_SCRIPT" --self >/dev/null 2>&1
  self_exit=$?
  assert_eq "0" "$self_exit" "shared self verification succeeds"
  if [ ! -e "$self_marker" ]; then
    pass "shared self verification never invokes pnpm"
  else
    fail "shared self verification never invokes pnpm"
  fi
else
  fail "shared verification implementation exists"
fi

claude_marker="$FIXTURE_ROOT/claude-pnpm"
(
  cd "$HARNESS_ROOT" &&
    printf '%s' '{"stop_hook_active":false}' |
      PATH="$FIXTURE_ROOT/bin:$PATH" PNPM_MARKER="$claude_marker" bash .claude/hooks/verify-before-stop.sh
) >/dev/null 2>&1
claude_exit=$?
if [ ! -e "$claude_marker" ]; then
  pass "Claude self Stop hook never invokes pnpm"
else
  fail "Claude self Stop hook never invokes pnpm"
fi
assert_eq "0" "$claude_exit" "Claude self Stop hook succeeds"

codex_marker="$FIXTURE_ROOT/codex-pnpm"
codex_output=$(
  cd "$HARNESS_ROOT" &&
    printf '%s' '{"stop_hook_active":false}' |
      PATH="$FIXTURE_ROOT/bin:$PATH" PNPM_MARKER="$codex_marker" bash .codex/hooks/verify-before-stop.sh
)
if [ ! -e "$codex_marker" ]; then
  pass "Codex self Stop hook never invokes pnpm"
else
  fail "Codex self Stop hook never invokes pnpm"
fi
codex_continue=$(printf '%s' "$codex_output" | jq -r '.continue' 2>/dev/null)
assert_eq "false" "$codex_continue" "Codex self Stop hook allows completion"

mkdir -p "$FIXTURE_ROOT/active/docs/specs"
printf '%s\n' '---' 'status: active' '---' 'project: fixture' > "$FIXTURE_ROOT/active/docs/specs/00_PROJECT_FACTS.md"
printf '%s\n' 'printf verified > "$VERIFY_MARKER"' > "$FIXTURE_ROOT/active/docs/specs/verify.cmd"
project_marker="$FIXTURE_ROOT/project-verified"
if [ -f "$VERIFY_SCRIPT" ]; then
  (
    cd "$FIXTURE_ROOT/active" &&
      VERIFY_MARKER="$project_marker" bash "$VERIFY_SCRIPT" --project
  ) >/dev/null 2>&1
  project_exit=$?
  assert_eq "0" "$project_exit" "active project verification succeeds"
  if [ -f "$project_marker" ]; then
    pass "active project verification runs declared command"
  else
    fail "active project verification runs declared command"
  fi
fi

mkdir -p "$FIXTURE_ROOT/draft/docs/specs"
printf '%s\n' '---' 'status: draft' '---' 'project: fixture' > "$FIXTURE_ROOT/draft/docs/specs/00_PROJECT_FACTS.md"
printf '%s\n' 'printf verified > "$VERIFY_MARKER"' > "$FIXTURE_ROOT/draft/docs/specs/verify.cmd"
draft_marker="$FIXTURE_ROOT/draft-verified"
if [ -f "$VERIFY_SCRIPT" ]; then
  (
    cd "$FIXTURE_ROOT/draft" &&
      VERIFY_MARKER="$draft_marker" bash "$VERIFY_SCRIPT" --project
  ) >/dev/null 2>&1
  draft_exit=$?
  if [ "$draft_exit" -ne 0 ]; then
    pass "draft project verification fails closed"
  else
    fail "draft project verification fails closed"
  fi
  if [ ! -e "$draft_marker" ]; then
    pass "draft project verification does not run declared command"
  else
    fail "draft project verification does not run declared command"
  fi
fi

finish_tests
