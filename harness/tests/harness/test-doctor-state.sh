#!/bin/bash
set -u

TEST_DIR=$(cd "$(dirname "$0")" && pwd -P)
HARNESS_ROOT=$(cd "$TEST_DIR/../.." && pwd -P)
. "$TEST_DIR/testlib.sh"

FIXTURE_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/harness-doctor-state.XXXXXX")
trap 'rm -rf "$FIXTURE_ROOT"' EXIT

make_project() {
  local name="$1"
  mkdir -p "$FIXTURE_ROOT/$name/docs/specs"
  printf '%s\n' '{"name":"doctor-fixture","scripts":{}}' > "$FIXTURE_ROOT/$name/package.json"
  printf '%s\n' '# paths' 'src/main.ts' > "$FIXTURE_ROOT/$name/docs/specs/dangerous-zones.txt"
  printf '%s\n' '# Index' > "$FIXTURE_ROOT/$name/docs/specs/INDEX.md"
}

run_doctor() {
  local project_root="$1"
  local output_file="$FIXTURE_ROOT/doctor-output"
  (
    cd "$project_root" &&
      bash "$HARNESS_ROOT/scripts/doctor.sh" --project --strict
  ) > "$output_file" 2>&1
  DOCTOR_EXIT=$?
  DOCTOR_OUTPUT=$(sed -n '1,160p' "$output_file")
}

make_project active
printf '%s\n' '---' 'status: active' '---' 'project: harness' > "$FIXTURE_ROOT/active/docs/specs/00_PROJECT_FACTS.md"
run_doctor "$FIXTURE_ROOT/active"
assert_eq "0" "$DOCTOR_EXIT" "strict doctor accepts active specs"
assert_contains "$DOCTOR_OUTPUT" "state=active" "doctor reports active state"

make_project draft
printf '%s\n' '---' 'status: draft' '---' 'project: harness' > "$FIXTURE_ROOT/draft/docs/specs/00_PROJECT_FACTS.md"
run_doctor "$FIXTURE_ROOT/draft"
if [ "$DOCTOR_EXIT" -ne 0 ]; then
  pass "strict doctor rejects draft specs"
else
  fail "strict doctor rejects draft specs"
fi
assert_contains "$DOCTOR_OUTPUT" "state=draft" "doctor reports draft state"

mkdir -p "$FIXTURE_ROOT/missing"
printf '%s\n' '{"name":"doctor-fixture","scripts":{}}' > "$FIXTURE_ROOT/missing/package.json"
run_doctor "$FIXTURE_ROOT/missing"
if [ "$DOCTOR_EXIT" -ne 0 ]; then
  pass "strict doctor rejects missing specs"
else
  fail "strict doctor rejects missing specs"
fi
assert_contains "$DOCTOR_OUTPUT" "state=missing" "doctor reports missing state"

finish_tests
