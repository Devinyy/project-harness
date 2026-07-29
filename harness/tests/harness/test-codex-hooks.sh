#!/bin/bash
set -u

TEST_DIR=$(cd "$(dirname "$0")" && pwd -P)
HARNESS_ROOT=$(cd "$TEST_DIR/../.." && pwd -P)
. "$TEST_DIR/testlib.sh"

FIXTURE_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/harness-codex-hooks.XXXXXX")
trap 'rm -rf "$FIXTURE_ROOT"' EXIT

git -C "$FIXTURE_ROOT" init -q
mkdir -p \
  "$FIXTURE_ROOT/.codex/hooks" \
  "$FIXTURE_ROOT/scripts/lib" \
  "$FIXTURE_ROOT/docs/specs" \
  "$FIXTURE_ROOT/nested/deeper" \
  "$FIXTURE_ROOT/src"
cp "$HARNESS_ROOT/.codex/config.toml" "$FIXTURE_ROOT/.codex/config.toml"
cp "$HARNESS_ROOT/.codex/hooks/"*.sh "$FIXTURE_ROOT/.codex/hooks/"
cp "$HARNESS_ROOT/scripts/verify-harness.sh" "$FIXTURE_ROOT/scripts/verify-harness.sh"
cp "$HARNESS_ROOT/scripts/run-verification-profile.sh" "$FIXTURE_ROOT/scripts/run-verification-profile.sh"
cp "$HARNESS_ROOT/scripts/lib/specs-state.sh" "$FIXTURE_ROOT/scripts/lib/specs-state.sh"
[ -f "$HARNESS_ROOT/scripts/lib/changed-files.sh" ] &&
  cp "$HARNESS_ROOT/scripts/lib/changed-files.sh" "$FIXTURE_ROOT/scripts/lib/changed-files.sh"

printf '%s\n' '---' 'status: active' '---' 'project: fixture' \
  > "$FIXTURE_ROOT/docs/specs/00_PROJECT_FACTS.md"
printf 'true\n' > "$FIXTURE_ROOT/docs/specs/verify.cmd"
printf 'private-area/\n' > "$FIXTURE_ROOT/docs/specs/dangerous-zones.txt"
printf 'base\n' > "$FIXTURE_ROOT/src/tracked.ts"
git -C "$FIXTURE_ROOT" add .
git -C "$FIXTURE_ROOT" \
  -c user.name=Harness \
  -c user.email=harness@example.invalid \
  commit -qm "fixture baseline"

run_codex_hook() {
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

assert_valid_decision() {
  local expected="$1"
  local payload="$2"
  local label="$3"
  local actual
  actual=$(printf '%s' "$payload" | jq -r '.decision // empty' 2>/dev/null)
  assert_eq "$expected" "$actual" "$label"
}

assert_valid_json() {
  local payload="$1"
  local label="$2"
  if printf '%s' "$payload" | jq -e . >/dev/null 2>&1; then
    pass "$label"
  else
    fail "$label"
  fi
}

pretool_matchers() {
  awk '
    /^\[\[hooks\.PreToolUse(\.hooks)?\]\]$/ {
      in_pre = 1
      next
    }
    /^\[\[hooks\./ {
      in_pre = 0
      next
    }
    in_pre && /^matcher = / {
      line = $0
      sub(/^matcher = "/, "", line)
      sub(/"$/, "", line)
      print line
    }
  ' "$FIXTURE_ROOT/.codex/config.toml"
}

matcher_accepts() {
  local tool_name="$1"
  local matcher
  while IFS= read -r matcher; do
    if [[ "$tool_name" =~ ^($matcher)$ ]]; then
      return 0
    fi
  done < <(pretool_matchers)
  return 1
}

for tool_name in Bash apply_patch Edit Write; do
  if matcher_accepts "$tool_name"; then
    pass "Codex PreToolUse registers $tool_name"
  else
    fail "Codex PreToolUse registers $tool_name"
  fi
done

BLOCK_HOOK="$FIXTURE_ROOT/.codex/hooks/block-dangerous-commands.sh"
run_codex_hook "$BLOCK_HOOK" '{"tool_input":{"command":"git status"}}'
assert_eq "0" "$HOOK_EXIT" "Codex shell hook exits successfully for safe commands"
assert_valid_decision "allow" "$HOOK_OUTPUT" "Codex allows safe shell commands"

run_codex_hook "$BLOCK_HOOK" '{"tool_input":{"command":"rm -rf ./cache"}}'
assert_eq "0" "$HOOK_EXIT" "Codex shell hook reports blocks through JSON"
assert_valid_decision "block" "$HOOK_OUTPUT" "Codex blocks dangerous shell commands"

run_codex_hook "$BLOCK_HOOK" '{malformed'
assert_eq "0" "$HOOK_EXIT" "Codex shell hook tolerates malformed JSON"
assert_valid_decision "allow" "$HOOK_OUTPUT" "Codex malformed input fails open with valid JSON"

run_codex_hook "$BLOCK_HOOK" ''
assert_eq "0" "$HOOK_EXIT" "Codex shell hook tolerates empty input"
assert_valid_decision "allow" "$HOOK_OUTPUT" "Codex empty input returns valid allow JSON"

GUARD_HOOK="$FIXTURE_ROOT/.codex/hooks/guard-dangerous-zones.sh"
if [ ! -f "$GUARD_HOOK" ]; then
  fail "Codex has a dedicated dangerous-zone hook"
else
  run_codex_hook "$GUARD_HOOK" '{"tool_input":{"file_path":"src/views/Normal.vue"}}'
  assert_valid_decision "allow" "$HOOK_OUTPUT" "Codex allows normal file edits"

  patch_input=$(printf '%s' '{"tool_name":"apply_patch","tool_input":{"patch":"*** Begin Patch\n*** Update File: private-area/config.ts\n@@\n-old\n+new\n*** End Patch"}}')
  run_codex_hook "$GUARD_HOOK" "$patch_input"
  assert_valid_decision "block" "$HOOK_OUTPUT" "Codex blocks apply_patch changes in project dangerous zones"
fi

pretool_commands=$(awk '
  /^\[\[hooks\.PreToolUse(\.hooks)?\]\]$/ {
    in_pre = 1
    next
  }
  /^\[\[hooks\./ {
    in_pre = 0
    next
  }
  in_pre && /^command = / {
    line = $0
    sub(/^command = '\''/, "", line)
    sub(/'\''$/, "", line)
    print line
  }
' "$FIXTURE_ROOT/.codex/config.toml")

nested_commands_ok=1
while IFS= read -r hook_command; do
  [ -z "$hook_command" ] && continue
  (
    cd "$FIXTURE_ROOT/nested/deeper" &&
      printf '%s' '{"tool_input":{"command":"git status","file_path":"src/views/Normal.vue"}}' |
        bash -c "$hook_command"
  ) >/dev/null 2>&1 || nested_commands_ok=0
done <<< "$pretool_commands"
if [ "$nested_commands_ok" -eq 1 ]; then
  pass "Codex configured hook commands resolve from nested directories"
else
  fail "Codex configured hook commands resolve from nested directories"
fi

mkdir -p "$FIXTURE_ROOT/bin"
printf '%s\n' \
  '#!/bin/bash' \
  'printf "%s\n" "$*" >> "$PNPM_MARKER"' \
  'exit 0' > "$FIXTURE_ROOT/bin/pnpm"
chmod +x "$FIXTURE_ROOT/bin/pnpm"
printf 'untracked\n' > "$FIXTURE_ROOT/src/untracked.ts"
pnpm_marker="$FIXTURE_ROOT/pnpm-invocations"
(
  cd "$FIXTURE_ROOT/nested/deeper" &&
    printf '%s' '{"tool_name":"apply_patch","tool_input":{}}' |
      PATH="$FIXTURE_ROOT/bin:$PATH" PNPM_MARKER="$pnpm_marker" \
        bash "$FIXTURE_ROOT/.codex/hooks/format-on-write.sh"
) >/dev/null 2>&1
format_exit=$?
assert_eq "0" "$format_exit" "Codex formatter succeeds from nested directories"
if [ -f "$pnpm_marker" ]; then
  format_calls=$(cat "$pnpm_marker")
else
  format_calls=""
fi
assert_contains "$format_calls" "src/untracked.ts" "Codex formatter includes untracked changed files"
rm -f "$FIXTURE_ROOT/src/untracked.ts" "$pnpm_marker"

printf 'safe note\n' > "$FIXTURE_ROOT/src/untracked-note.md"
run_codex_hook "$FIXTURE_ROOT/.codex/hooks/verify-before-stop.sh" '{"stop_hook_active":false}'
assert_valid_json "$HOOK_OUTPUT" "Codex Stop summary returns valid JSON"
assert_contains "$HOOK_OUTPUT" "src/untracked-note.md" "Codex Stop summary includes untracked files from nested directories"
rm -f "$FIXTURE_ROOT/src/untracked-note.md"

mkdir -p "$FIXTURE_ROOT/private-area"
printf 'dangerous\n' > "$FIXTURE_ROOT/private-area/untracked.md"
run_codex_hook "$FIXTURE_ROOT/.codex/hooks/verify-before-stop.sh" '{"stop_hook_active":false}'
assert_valid_json "$HOOK_OUTPUT" "Codex dangerous-zone Stop response returns valid JSON"
assert_contains "$HOOK_OUTPUT" "检测到危险区文件" "Codex Stop detects untracked dangerous files"
assert_contains "$HOOK_OUTPUT" "private-area/untracked.md" "Codex Stop reports the untracked dangerous path"

finish_tests
