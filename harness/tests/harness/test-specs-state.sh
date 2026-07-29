#!/bin/bash
set -u

TEST_DIR=$(cd "$(dirname "$0")" && pwd -P)
HARNESS_ROOT=$(cd "$TEST_DIR/../.." && pwd -P)
. "$TEST_DIR/testlib.sh"

STATE_SCRIPT="$HARNESS_ROOT/scripts/lib/specs-state.sh"
if [ ! -f "$STATE_SCRIPT" ]; then
  fail "shared specs-state implementation exists"
  finish_tests
fi

FIXTURE_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/harness-specs-state.XXXXXX")
trap 'rm -rf "$FIXTURE_ROOT"' EXIT

state_for() {
  (
    . "$STATE_SCRIPT"
    specs_state "$1"
  )
}

mkdir -p "$FIXTURE_ROOT/missing"
assert_eq "missing" "$(state_for "$FIXTURE_ROOT/missing")" "missing facts file reports missing"

mkdir -p "$FIXTURE_ROOT/placeholder/docs/specs"
printf '%s\n' '---' 'status: active' '---' 'project: <项目名>' > "$FIXTURE_ROOT/placeholder/docs/specs/00_PROJECT_FACTS.md"
assert_eq "draft" "$(state_for "$FIXTURE_ROOT/placeholder")" "placeholder-bearing specs report draft"

mkdir -p "$FIXTURE_ROOT/draft-status/docs/specs"
printf '%s\n' '---' 'status: draft' '---' 'project: harness' > "$FIXTURE_ROOT/draft-status/docs/specs/00_PROJECT_FACTS.md"
assert_eq "draft" "$(state_for "$FIXTURE_ROOT/draft-status")" "draft frontmatter reports draft"

mkdir -p "$FIXTURE_ROOT/missing-status/docs/specs"
printf '%s\n' '# Project facts' 'project: harness' > "$FIXTURE_ROOT/missing-status/docs/specs/00_PROJECT_FACTS.md"
assert_eq "draft" "$(state_for "$FIXTURE_ROOT/missing-status")" "facts without active status report draft"

mkdir -p "$FIXTURE_ROOT/active/docs/specs"
printf '%s\n' '---' 'status: active' '---' 'project: harness' > "$FIXTURE_ROOT/active/docs/specs/00_PROJECT_FACTS.md"
printf '%s\n' '# Index' 'Plain files without frontmatter are valid.' > "$FIXTURE_ROOT/active/docs/specs/INDEX.md"
assert_eq "active" "$(state_for "$FIXTURE_ROOT/active")" "reviewed specs report active"

draft_init_output=$(
  cd "$FIXTURE_ROOT/draft-status" &&
    bash "$HARNESS_ROOT/scripts/init-specs.sh" 2>&1
)
assert_contains "$draft_init_output" "draft" "initializer identifies existing draft specs"
assert_not_contains "$draft_init_output" "视为已初始化" "initializer does not promote draft specs"

active_init_output=$(
  cd "$FIXTURE_ROOT/active" &&
    bash "$HARNESS_ROOT/scripts/init-specs.sh" 2>&1
)
assert_contains "$active_init_output" "active" "initializer identifies reviewed specs"

finish_tests
