#!/bin/bash
set -u

TEST_DIR=$(cd "$(dirname "$0")" && pwd -P)
HARNESS_ROOT=$(cd "$TEST_DIR/../.." && pwd -P)
. "$TEST_DIR/testlib.sh"

expected_sections=$(printf '%s\n' Allowed Blocked "Ask First")

for flavor in pc-microapp miniprogram-uniapp; do
  policy_file="$HARNESS_ROOT/spec-templates/$flavor/13_AGENT_POLICY.md"
  if [ ! -f "$policy_file" ]; then
    fail "$flavor agent policy exists"
    continue
  fi

  sections=$(sed -n 's/^## //p' "$policy_file")
  assert_eq "$expected_sections" "$sections" "$flavor policy has exactly Allowed, Blocked, Ask First sections"

  policy_text=$(cat "$policy_file")
  for required_topic in \
    "destructive" "dependency" "network" "dangerous zone" "business semantics" "external writes"; do
    assert_contains "$policy_text" "$required_topic" "$flavor policy covers $required_topic"
  done
  assert_contains "$policy_text" "审计记录" "$flavor policy scopes raw-content restrictions to audit records"
  assert_not_contains "$policy_text" "读取、记录或输出" "$flavor policy does not block ordinary source inspection"

  index_text=$(cat "$HARNESS_ROOT/spec-templates/$flavor/INDEX.md")
  assert_contains "$index_text" "13_AGENT_POLICY" "$flavor index exposes the agent policy"
done

schema_text=$(cat "$HARNESS_ROOT/spec-templates/SCHEMA.md")
assert_contains "$schema_text" "13_AGENT_POLICY.md" "spec schema requires the agent policy"
assert_contains "$(cat "$HARNESS_ROOT/AGENTS.md")" "13_AGENT_POLICY.md" "AGENTS.md routes agents to project policy"
assert_contains "$(cat "$HARNESS_ROOT/CLAUDE.md")" "13_AGENT_POLICY.md" "CLAUDE.md routes Claude to project policy"

FIXTURE_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/harness-agent-policy.XXXXXX")
trap 'rm -rf "$FIXTURE_ROOT"' EXIT
for flavor in pc mini; do
  project_root="$FIXTURE_ROOT/$flavor"
  template_flavor="pc-microapp"
  [ "$flavor" = "mini" ] && template_flavor="miniprogram-uniapp"
  mkdir -p "$project_root/scripts/lib" "$project_root/spec-templates"
  cp "$HARNESS_ROOT/scripts/init-specs.sh" "$project_root/scripts/"
  cp "$HARNESS_ROOT/scripts/lib/specs-state.sh" "$project_root/scripts/lib/"
  cp -R "$HARNESS_ROOT/spec-templates/$template_flavor" "$project_root/spec-templates/"
  (
    cd "$project_root" &&
      bash scripts/init-specs.sh --flavor "$flavor"
  ) >/dev/null
  if [ -f "$project_root/docs/specs/13_AGENT_POLICY.md" ]; then
    pass "$flavor initializer installs the agent policy"
  else
    fail "$flavor initializer installs the agent policy"
  fi
done

finish_tests
