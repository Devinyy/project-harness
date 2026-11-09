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
  git -C "$FIXTURE_ROOT/$name" init -q
  printf '%s\n' '{"name":"doctor-fixture","scripts":{}}' > "$FIXTURE_ROOT/$name/package.json"
  printf '%s\n' '# paths' 'src/main.ts' > "$FIXTURE_ROOT/$name/docs/specs/dangerous-zones.txt"
  printf '%s\n' '# Index' > "$FIXTURE_ROOT/$name/docs/specs/INDEX.md"
}

last_audit_record() {
  local project_root="$1"
  local events_file
  events_file="$(git -C "$project_root" rev-parse --absolute-git-dir)/harness/events.jsonl"
  jq -sc 'last // {}' "$events_file" 2>/dev/null
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

v2_empty="$FIXTURE_ROOT/v2-empty"
make_project v2-empty
printf '%s\n' '2.0.0' > "$v2_empty/VERSION"
cp -R "$HARNESS_ROOT/project-templates" "$v2_empty/"
mkdir -p "$v2_empty/scripts/lib"
cp "$HARNESS_ROOT/scripts/init-project-knowledge.sh" "$v2_empty/scripts/"
cp "$HARNESS_ROOT/scripts/doctor.sh" "$v2_empty/scripts/"
cp "$HARNESS_ROOT/scripts/lib/specs-state.sh" "$v2_empty/scripts/lib/"
cp "$HARNESS_ROOT/scripts/lib/knowledge-manifest.sh" "$v2_empty/scripts/lib/"
cp "$HARNESS_ROOT/MAP.md" "$v2_empty/MAP.md"
printf '%s\n' '---' 'status: active' '---' 'project: installed 2.0 without knowledge domains' > "$v2_empty/docs/specs/00_PROJECT_FACTS.md"
run_doctor "$v2_empty"
assert_eq "0" "$DOCTOR_EXIT" "strict doctor accepts Harness 2 project before knowledge initialization"
assert_contains "$DOCTOR_OUTPUT" "PROJECT_MAP.md 暂为可选" "PROJECT_MAP remains optional before a knowledge domain is generated"
assert_not_contains "$DOCTOR_OUTPUT" "缺少 PROJECT_MAP.md（2.0 项目资料登记入口）" "empty Harness 2 project has no PROJECT_MAP readiness failure"

make_project legacy-version
printf '%s\n' '1.7.3' > "$FIXTURE_ROOT/legacy-version/VERSION"
printf '%s\n' '---' 'status: active' '---' 'project: legacy' > "$FIXTURE_ROOT/legacy-version/docs/specs/00_PROJECT_FACTS.md"
run_doctor "$FIXTURE_ROOT/legacy-version"
assert_eq "0" "$DOCTOR_EXIT" "strict doctor accepts legacy project VERSION without Harness 2 assets"
assert_not_contains "$DOCTOR_OUTPUT" "VERSION 必须是 2.0.0" "legacy project VERSION is not treated as Harness 2"

v2_custom_map="$FIXTURE_ROOT/v2-custom-map"
mkdir -p "$v2_custom_map/docs/specs" "$v2_custom_map/design"
git -C "$v2_custom_map" init -q
printf '%s\n' '{"name":"doctor-v2-fixture","scripts":{}}' > "$v2_custom_map/package.json"
printf '%s\n' '2.0.0' > "$v2_custom_map/VERSION"
printf '%s\n' '---' 'status: active' '---' 'project: v2 custom map' > "$v2_custom_map/docs/specs/00_PROJECT_FACTS.md"
printf '%s\n' '# Index' > "$v2_custom_map/docs/specs/INDEX.md"
printf '%s\n' '# dangerous zones' > "$v2_custom_map/docs/specs/dangerous-zones.txt"
cp -R "$HARNESS_ROOT/project-templates" "$v2_custom_map/"
mkdir -p "$v2_custom_map/scripts/lib"
cp "$HARNESS_ROOT/scripts/init-project-knowledge.sh" "$v2_custom_map/scripts/"
cp "$HARNESS_ROOT/scripts/doctor.sh" "$v2_custom_map/scripts/"
cp "$HARNESS_ROOT/scripts/lib/specs-state.sh" "$v2_custom_map/scripts/lib/"
cp "$HARNESS_ROOT/scripts/lib/knowledge-manifest.sh" "$v2_custom_map/scripts/lib/"
cp "$HARNESS_ROOT/MAP.md" "$v2_custom_map/MAP.md"
cp "$HARNESS_ROOT/project-templates/design/MAP.md" "$v2_custom_map/design/MAP.md"
printf '%s\n' '# user-owned index' '- [Design](./design/MAP.md)' > "$v2_custom_map/PROJECT_MAP.md"
run_doctor "$v2_custom_map"
assert_eq "0" "$DOCTOR_EXIT" "strict doctor accepts custom PROJECT_MAP title"
assert_not_contains "$DOCTOR_OUTPUT" "独立项目资料登记标题" "custom PROJECT_MAP title is not required"
assert_contains "$DOCTOR_OUTPUT" "PROJECT_MAP link: ./design/MAP.md" "custom PROJECT_MAP generated link is validated"

make_project draft
printf '%s\n' '---' 'status: draft' '---' 'project: harness' > "$FIXTURE_ROOT/draft/docs/specs/00_PROJECT_FACTS.md"
run_doctor "$FIXTURE_ROOT/draft"
if [ "$DOCTOR_EXIT" -ne 0 ]; then
  pass "strict doctor rejects draft specs"
else
  fail "strict doctor rejects draft specs"
fi
assert_contains "$DOCTOR_OUTPUT" "state=draft" "doctor reports draft state"
draft_audit=$(last_audit_record "$FIXTURE_ROOT/draft")
assert_eq \
  '{"adapter":"harness","event":"session_start","category":"specs_draft","decision":"fail","exit_status":1}' \
  "$(printf '%s' "$draft_audit" | jq -c '{adapter,event,category,decision,exit_status}')" \
  "strict doctor records draft readiness failure"

mkdir -p "$FIXTURE_ROOT/missing"
git -C "$FIXTURE_ROOT/missing" init -q
printf '%s\n' '{"name":"doctor-fixture","scripts":{}}' > "$FIXTURE_ROOT/missing/package.json"
run_doctor "$FIXTURE_ROOT/missing"
if [ "$DOCTOR_EXIT" -ne 0 ]; then
  pass "strict doctor rejects missing specs"
else
  fail "strict doctor rejects missing specs"
fi
assert_contains "$DOCTOR_OUTPUT" "state=missing" "doctor reports missing state"
missing_audit=$(last_audit_record "$FIXTURE_ROOT/missing")
assert_eq "specs_missing" "$(printf '%s' "$missing_audit" | jq -r '.category')" "strict doctor records missing readiness failure"
assert_eq "fail" "$(printf '%s' "$missing_audit" | jq -r '.decision')" "strict doctor marks readiness as failed"

mkdir -p "$FIXTURE_ROOT/session-missing"
git -C "$FIXTURE_ROOT/session-missing" init -q
printf '%s\n' '{"name":"doctor-fixture","scripts":{}}' > "$FIXTURE_ROOT/session-missing/package.json"
(
  cd "$FIXTURE_ROOT/session-missing" &&
    bash "$HARNESS_ROOT/scripts/doctor.sh" --project
) >/dev/null 2>&1
session_doctor_exit=$?
session_audit=$(last_audit_record "$FIXTURE_ROOT/session-missing")
assert_eq "0" "$session_doctor_exit" "SessionStart doctor keeps missing specs advisory"
assert_eq \
  '{"category":"specs_missing","decision":"warn","exit_status":0}' \
  "$(printf '%s' "$session_audit" | jq -c '{category,decision,exit_status}')" \
  "SessionStart doctor records advisory readiness"

finish_tests
