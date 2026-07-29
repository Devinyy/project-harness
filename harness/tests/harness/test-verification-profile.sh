#!/bin/bash
set -u

TEST_DIR=$(cd "$(dirname "$0")" && pwd -P)
HARNESS_ROOT=$(cd "$TEST_DIR/../.." && pwd -P)
. "$TEST_DIR/testlib.sh"

FIXTURE_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/harness-verification-profile.XXXXXX")
trap 'rm -rf "$FIXTURE_ROOT"' EXIT

RUNNER="$HARNESS_ROOT/scripts/run-verification-profile.sh"
if [ ! -f "$RUNNER" ]; then
  fail "verification profile runner exists"
  finish_tests
  exit 1
fi

run_profile() {
  local project_root="$1"
  shift
  local output_file="$project_root/profile-output"

  (
    cd "$project_root" &&
      PROFILE_LOG="$project_root/profile-log" \
      FAIL_FLAG="$project_root/fail-flag" \
      bash "$RUNNER" "$@"
  ) >"$output_file" 2>&1
  PROFILE_EXIT=$?
  PROFILE_OUTPUT=$(cat "$output_file")
}

make_specs_dir() {
  mkdir -p "$1/docs/specs"
}

# full = fast commands, then full commands; comments and blank lines are ignored.
ordered_root="$FIXTURE_ROOT/ordered"
make_specs_dir "$ordered_root"
printf '%s\n' \
  '# fast checks' \
  'printf "fast-1\n" >> "$PROFILE_LOG"' \
  '' \
  'printf "fast-2\n" >> "$PROFILE_LOG"' \
  > "$ordered_root/docs/specs/verify.cmd"
printf '%s\n' \
  '# full checks' \
  'printf "full-1\n" >> "$PROFILE_LOG"' \
  '' \
  'printf "full-2\n" >> "$PROFILE_LOG"' \
  > "$ordered_root/docs/specs/verify.full.cmd"
run_profile "$ordered_root" full
assert_eq "0" "$PROFILE_EXIT" "full profile succeeds when all commands pass"
ordered_log=$(cat "$ordered_root/profile-log")
expected_order=$(printf '%s\n' fast-1 fast-2 full-1 full-2)
assert_eq "$expected_order" "$ordered_log" "full profile runs fast then full commands in file order"

# Normal execution stops at the first failure.
stop_root="$FIXTURE_ROOT/stop-first"
make_specs_dir "$stop_root"
printf '%s\n' \
  'printf "before\n" >> "$PROFILE_LOG"' \
  'exit 7' \
  'printf "after\n" >> "$PROFILE_LOG"' \
  > "$stop_root/docs/specs/verify.cmd"
run_profile "$stop_root" fast
assert_eq "7" "$PROFILE_EXIT" "fast profile preserves the first failing exit code"
stop_log=$(cat "$stop_root/profile-log")
assert_eq "before" "$stop_log" "normal profile stops before later commands"

# Full remains backwards-compatible when only verify.cmd exists.
legacy_root="$FIXTURE_ROOT/legacy"
make_specs_dir "$legacy_root"
printf '%s\n' 'printf "legacy-fast\n" >> "$PROFILE_LOG"' \
  > "$legacy_root/docs/specs/verify.cmd"
run_profile "$legacy_root" full
assert_eq "0" "$PROFILE_EXIT" "full profile accepts a missing optional verify.full.cmd"
legacy_log=$(cat "$legacy_root/profile-log")
assert_eq "legacy-fast" "$legacy_log" "legacy verify.cmd remains the fast profile"

# A file containing only comments is not a runnable fast profile.
empty_root="$FIXTURE_ROOT/empty"
make_specs_dir "$empty_root"
printf '%s\n' '# typecheck: 未探测到' '' > "$empty_root/docs/specs/verify.cmd"
run_profile "$empty_root" fast
assert_eq "2" "$PROFILE_EXIT" "empty fast profile fails with a configuration error"
assert_contains "$PROFILE_OUTPUT" "没有可执行命令" "empty fast profile explains the missing command"

# Snapshot records every command/exit pair, including failures.
snapshot_root="$FIXTURE_ROOT/snapshot"
make_specs_dir "$snapshot_root"
printf '%s\n' \
  'printf "snapshot-pass\n" >> "$PROFILE_LOG"' \
  'exit 5' \
  > "$snapshot_root/docs/specs/verify.cmd"
snapshot_file="$snapshot_root/baseline.jsonl"
run_profile "$snapshot_root" fast --snapshot "$snapshot_file"
assert_eq "0" "$PROFILE_EXIT" "snapshot mode records failures without blocking baseline creation"
snapshot_count=$(jq -s 'length' "$snapshot_file" 2>/dev/null)
assert_eq "2" "$snapshot_count" "snapshot records every command"
snapshot_exits=$(jq -sr 'map(.exit) | join(",")' "$snapshot_file" 2>/dev/null)
assert_eq "0,5" "$snapshot_exits" "snapshot stores command exit codes in order"

missing_snapshot_file="$snapshot_root/missing/baseline.jsonl"
run_profile "$snapshot_root" fast --snapshot "$missing_snapshot_file"
if [ "$PROFILE_EXIT" -ne 0 ]; then
  pass "snapshot fails when the target file cannot be created"
else
  fail "snapshot fails when the target file cannot be created"
fi

# Compare warns for pre-existing failures but does not block them.
run_profile "$snapshot_root" fast --compare "$snapshot_file"
assert_eq "0" "$PROFILE_EXIT" "compare allows failures already present in the baseline"
assert_contains "$PROFILE_OUTPUT" "历史失败" "compare keeps pre-existing failures visible"

# Compare blocks a newly failing command and still evaluates later commands.
compare_root="$FIXTURE_ROOT/compare"
make_specs_dir "$compare_root"
printf '%s\n' \
  'test ! -f "$FAIL_FLAG"' \
  'printf "after-compare\n" >> "$PROFILE_LOG"' \
  > "$compare_root/docs/specs/verify.cmd"
compare_file="$compare_root/baseline.jsonl"
run_profile "$compare_root" fast --snapshot "$compare_file"
touch "$compare_root/fail-flag"
rm -f "$compare_root/profile-log"
run_profile "$compare_root" fast --compare "$compare_file"
if [ "$PROFILE_EXIT" -ne 0 ]; then
  pass "compare blocks newly failing commands"
else
  fail "compare blocks newly failing commands"
fi
assert_contains "$PROFILE_OUTPUT" "新增失败" "compare identifies newly failing commands"
compare_log=$(cat "$compare_root/profile-log")
assert_eq "after-compare" "$compare_log" "compare evaluates all commands before deciding"

# init-specs discovers only scripts that actually exist for each flavor.
prepare_initializer_fixture() {
  local project_root="$1"
  mkdir -p "$project_root"
  cp -R "$HARNESS_ROOT/spec-templates" "$project_root/spec-templates"
}

pc_root="$FIXTURE_ROOT/init-pc"
prepare_initializer_fixture "$pc_root"
printf '%s\n' \
  '{' \
  '  "scripts": {' \
  '    "validate": "vue-tsc --noEmit",' \
  '    "lint": "eslint .",' \
  '    "build": "vite build",' \
  '    "test": "vitest run"' \
  '  }' \
  '}' > "$pc_root/package.json"
(
  cd "$pc_root" &&
    bash "$HARNESS_ROOT/scripts/init-specs.sh" --flavor pc
) >/dev/null 2>&1
pc_fast=$(grep -vE '^[[:space:]]*(#|$)' "$pc_root/docs/specs/verify.cmd")
pc_full=$(grep -vE '^[[:space:]]*(#|$)' "$pc_root/docs/specs/verify.full.cmd")
assert_eq "pnpm run validate" "$pc_fast" "PC initializer discovers the real typecheck script"
assert_contains "$pc_full" "pnpm run lint" "PC full profile discovers lint"
assert_contains "$pc_full" "pnpm run build" "PC full profile discovers build"
assert_contains "$pc_full" "pnpm run test" "PC full profile includes an existing test script"

mini_root="$FIXTURE_ROOT/init-mini"
prepare_initializer_fixture "$mini_root"
printf '%s\n' \
  '{' \
  '  "scripts": {' \
  '    "lint:type": "vue-tsc --noEmit",' \
  '    "lint:ts": "eslint src",' \
  '    "build:h5": "uni build -p h5",' \
  '    "smoke:mp-weixin": "node smoke.js"' \
  '  }' \
  '}' > "$mini_root/package.json"
(
  cd "$mini_root" &&
    bash "$HARNESS_ROOT/scripts/init-specs.sh" --flavor mini
) >/dev/null 2>&1
mini_fast=$(grep -vE '^[[:space:]]*(#|$)' "$mini_root/docs/specs/verify.cmd")
mini_full=$(grep -vE '^[[:space:]]*(#|$)' "$mini_root/docs/specs/verify.full.cmd")
assert_eq "pnpm run lint:type" "$mini_fast" "uni-app initializer discovers the real typecheck script"
assert_contains "$mini_full" "pnpm run lint:ts" "uni-app full profile discovers lint"
assert_contains "$mini_full" "pnpm run build:h5" "uni-app full profile discovers an existing build"
assert_contains "$mini_full" "pnpm run smoke:mp-weixin" "uni-app full profile discovers an existing platform smoke command"
assert_not_contains "$mini_full" "pnpm test" "uni-app initializer never invents pnpm test"
assert_not_contains "$mini_full" "pnpm run test" "uni-app initializer never invents a test script"
mini_full_source=$(cat "$mini_root/docs/specs/verify.full.cmd")
assert_contains "$mini_full_source" "# test: 未探测到" "uni-app initializer documents the unavailable test category"

no_scripts_root="$FIXTURE_ROOT/init-no-scripts"
prepare_initializer_fixture "$no_scripts_root"
printf '%s\n' '{"scripts": {}}' > "$no_scripts_root/package.json"
(
  cd "$no_scripts_root" &&
    bash "$HARNESS_ROOT/scripts/init-specs.sh" --flavor pc
) >/dev/null 2>&1
no_scripts_fast=$(grep -vE '^[[:space:]]*(#|$)' "$no_scripts_root/docs/specs/verify.cmd" || true)
assert_eq "" "$no_scripts_fast" "initializer does not invent a typecheck command"
no_scripts_fast_source=$(cat "$no_scripts_root/docs/specs/verify.cmd")
assert_contains "$no_scripts_fast_source" "# typecheck: 未探测到" "initializer documents a missing typecheck"
no_scripts_full_source=$(cat "$no_scripts_root/docs/specs/verify.full.cmd")
assert_contains "$no_scripts_full_source" "# lint: 未探测到" "initializer documents a missing lint command"
assert_contains "$no_scripts_full_source" "# build: 未探测到" "initializer documents a missing build command"
assert_contains "$no_scripts_full_source" "# test: 未探测到" "PC initializer documents a missing test command"

# Both Stop adapters execute every fast command and never execute full checks.
hook_root="$FIXTURE_ROOT/hooks"
mkdir -p \
  "$hook_root/.claude/hooks" \
  "$hook_root/.codex/hooks" \
  "$hook_root/scripts/lib" \
  "$hook_root/docs/specs"
cp "$HARNESS_ROOT/.claude/hooks/verify-before-stop.sh" "$hook_root/.claude/hooks/"
cp "$HARNESS_ROOT/.codex/hooks/verify-before-stop.sh" "$hook_root/.codex/hooks/"
cp "$HARNESS_ROOT/scripts/verify-harness.sh" "$hook_root/scripts/"
cp "$HARNESS_ROOT/scripts/run-verification-profile.sh" "$hook_root/scripts/"
cp "$HARNESS_ROOT/scripts/lib/specs-state.sh" "$hook_root/scripts/lib/"
cp "$HARNESS_ROOT/scripts/lib/changed-files.sh" "$hook_root/scripts/lib/"
printf '%s\n' '---' 'status: active' '---' 'project: fixture' \
  > "$hook_root/docs/specs/00_PROJECT_FACTS.md"
printf '%s\n' \
  'printf "fast-1\n" >> "$PROFILE_LOG"' \
  'printf "fast-2\n" >> "$PROFILE_LOG"' \
  > "$hook_root/docs/specs/verify.cmd"
printf '%s\n' 'printf "full\n" >> "$PROFILE_LOG"' \
  > "$hook_root/docs/specs/verify.full.cmd"
git -C "$hook_root" init -q
git -C "$hook_root" add .
git -C "$hook_root" \
  -c user.name=Harness \
  -c user.email=harness@example.invalid \
  commit -qm "fixture baseline"

claude_log="$hook_root/claude-profile"
(
  cd "$hook_root" &&
    printf '%s' '{"stop_hook_active":false}' |
      PROFILE_LOG="$claude_log" bash .claude/hooks/verify-before-stop.sh
) >/dev/null 2>&1
claude_hook_exit=$?
assert_eq "0" "$claude_hook_exit" "Claude Stop succeeds with the fast profile"
claude_commands=$(cat "$claude_log")
assert_eq "$(printf '%s\n' fast-1 fast-2)" "$claude_commands" "Claude Stop runs every fast command and skips full"

codex_log="$hook_root/codex-profile"
codex_output=$(
  cd "$hook_root" &&
    printf '%s' '{"stop_hook_active":false}' |
      PROFILE_LOG="$codex_log" bash .codex/hooks/verify-before-stop.sh
)
codex_hook_exit=$?
assert_eq "0" "$codex_hook_exit" "Codex Stop reports the fast profile through JSON"
codex_commands=$(cat "$codex_log")
assert_eq "$(printf '%s\n' fast-1 fast-2)" "$codex_commands" "Codex Stop runs every fast command and skips full"
codex_continue=$(printf '%s' "$codex_output" | jq -r '.continue')
assert_eq "false" "$codex_continue" "Codex Stop allows completion after the fast profile"

finish_tests
