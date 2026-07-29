#!/bin/bash
set -u

TEST_DIR=$(cd "$(dirname "$0")" && pwd -P)
HARNESS_ROOT=$(cd "$TEST_DIR/../.." && pwd -P)
. "$TEST_DIR/testlib.sh"

FIXTURE_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/harness-audit-record.XXXXXX")
trap 'rm -rf "$FIXTURE_ROOT"' EXIT

RECORDER="$HARNESS_ROOT/scripts/record-harness-event.sh"
if [ ! -f "$RECORDER" ]; then
  fail "audit recorder exists"
  finish_tests
  exit 1
fi

git -C "$FIXTURE_ROOT" init -q
mkdir -p "$FIXTURE_ROOT/nested/deeper"

(
  cd "$FIXTURE_ROOT/nested/deeper" &&
    bash "$RECORDER" \
      --adapter claude \
      --event pre_tool_use \
      --category destructive_operation \
      --decision block \
      --exit 2
)

secret_value='sk-stage4-super-secret'
raw_prompt='delete production now'
raw_command='rm -rf /private/project'
file_content='customer_token=top-secret-value'
(
  cd "$FIXTURE_ROOT/nested/deeper" &&
    OPENAI_API_KEY="$secret_value" \
    RAW_PROMPT="$raw_prompt" \
    bash "$RECORDER" \
      --adapter "codex
$secret_value" \
      --event "$raw_prompt" \
      --category "$raw_command" \
      --decision "$file_content" \
      --exit 'not-a-number'
)
(
  cd "$FIXTURE_ROOT/nested/deeper" &&
    bash "$RECORDER" \
      --adapter harness \
      --event stop \
      --category verification_failed \
      --decision fail \
      --exit '1-2'
)

events_file="$(git -C "$FIXTURE_ROOT" rev-parse --absolute-git-dir)/harness/events.jsonl"
if [ -f "$events_file" ]; then
  pass "audit records are stored under the repository git path"
  events_text=$(cat "$events_file")
else
  fail "audit records are stored under the repository git path"
  events_text=""
fi

if printf '%s\n' "$events_text" | jq -s -e 'length == 3' >/dev/null 2>&1; then
  pass "audit output is valid JSONL"
else
  fail "audit output is valid JSONL"
fi

schema_ok=$(
  printf '%s\n' "$events_text" |
    jq -s -r '
      all(.[];
        (keys | sort) == ["adapter","category","decision","event","exit_status","timestamp"] and
        (.timestamp | type) == "string" and
        (.adapter | type) == "string" and
        (.event | type) == "string" and
        (.category | type) == "string" and
        (.decision | type) == "string" and
        (.exit_status | type) == "number"
      )
    ' 2>/dev/null
)
assert_eq "true" "$schema_ok" "every audit record has the required typed schema"

first_record=$(
  printf '%s\n' "$events_text" |
    jq -s -c '.[0] | {adapter,event,category,decision,exit_status}' 2>/dev/null
)
assert_eq \
  '{"adapter":"claude","event":"pre_tool_use","category":"destructive_operation","decision":"block","exit_status":2}' \
  "$first_record" \
  "known audit metadata is preserved"

second_record=$(
  printf '%s\n' "$events_text" |
    jq -s -c '.[1] | {adapter,event,category,decision,exit_status}' 2>/dev/null
)
assert_eq \
  '{"adapter":"unknown","event":"unknown","category":"unknown","decision":"unknown","exit_status":-1}' \
  "$second_record" \
  "unrecognized metadata is reduced to safe values"

third_exit_status=$(
  printf '%s\n' "$events_text" |
    jq -s -r '.[2].exit_status // empty' 2>/dev/null
)
assert_eq "-1" "$third_exit_status" "malformed numeric exit status is safely normalized"

for sensitive_text in "$secret_value" "$raw_prompt" "$raw_command" "$file_content" "OPENAI_API_KEY"; do
  assert_not_contains "$events_text" "$sensitive_text" "audit records exclude sensitive payload: $sensitive_text"
done

# Linked worktrees get their own private git-path audit file.
worktree_repo="$FIXTURE_ROOT/worktree-repo"
linked_root="$FIXTURE_ROOT/worktree-linked"
mkdir -p "$worktree_repo"
git -C "$worktree_repo" init -q
git -C "$worktree_repo" \
  -c user.name=Harness \
  -c user.email=harness@example.invalid \
  commit --allow-empty -qm "fixture baseline"
git -C "$worktree_repo" worktree add -qb audit-linked "$linked_root"
(
  cd "$linked_root" &&
    bash "$RECORDER" \
      --adapter codex --event post_tool_use --category explicit_approval --decision approve --exit 0
)
linked_events_file="$(git -C "$linked_root" rev-parse --absolute-git-dir)/harness/events.jsonl"
main_events_file="$(git -C "$worktree_repo" rev-parse --absolute-git-dir)/harness/events.jsonl"
if [ -f "$linked_events_file" ]; then
  pass "linked worktrees store audit records in their own git path"
else
  fail "linked worktrees store audit records in their own git path"
fi
if [ "$main_events_file" != "$linked_events_file" ]; then
  pass "linked worktree audit path is separate from the main worktree"
else
  fail "linked worktree audit path is separate from the main worktree"
fi

# Concurrent writers must preserve complete JSONL records.
parallel_root="$FIXTURE_ROOT/parallel"
mkdir -p "$parallel_root"
git -C "$parallel_root" init -q
for writer_id in $(seq 1 24); do
  (
    cd "$parallel_root" &&
      bash "$RECORDER" \
        --adapter harness --event stop --category verification_failed --decision fail --exit "$writer_id"
  ) &
done
wait
parallel_events_file="$(git -C "$parallel_root" rev-parse --absolute-git-dir)/harness/events.jsonl"
parallel_count=$(jq -s 'length' "$parallel_events_file" 2>/dev/null)
assert_eq "24" "$parallel_count" "concurrent audit writers preserve every JSONL record"

# Recording failures are advisory and must never block the caller.
mkdir -p "$FIXTURE_ROOT/fake-bin"
printf '%s\n' \
  '#!/bin/bash' \
  'printf "/dev/null/harness/events.jsonl\n"' \
  'exit 0' > "$FIXTURE_ROOT/fake-bin/git"
chmod +x "$FIXTURE_ROOT/fake-bin/git"
PATH="$FIXTURE_ROOT/fake-bin:$PATH" \
  bash "$RECORDER" \
    --adapter harness \
    --event stop \
    --category verification_failed \
    --decision fail \
    --exit 1 >/dev/null 2>&1
record_failure_exit=$?
assert_eq "0" "$record_failure_exit" "audit write failures never block the caller"

# Hook integration records only categories/decisions, never raw inputs.
hook_root="$FIXTURE_ROOT/hooks"
mkdir -p \
  "$hook_root/.claude/hooks" \
  "$hook_root/.codex/hooks" \
  "$hook_root/scripts/lib" \
  "$hook_root/docs/specs"
cp "$HARNESS_ROOT/.claude/hooks/block-dangerous-commands.sh" "$hook_root/.claude/hooks/"
cp "$HARNESS_ROOT/.claude/hooks/guard-dangerous-zones.sh" "$hook_root/.claude/hooks/"
cp "$HARNESS_ROOT/.claude/hooks/verify-before-stop.sh" "$hook_root/.claude/hooks/"
cp "$HARNESS_ROOT/.codex/hooks/block-dangerous-commands.sh" "$hook_root/.codex/hooks/"
cp "$HARNESS_ROOT/.codex/hooks/guard-dangerous-zones.sh" "$hook_root/.codex/hooks/"
cp "$HARNESS_ROOT/.codex/hooks/verify-before-stop.sh" "$hook_root/.codex/hooks/"
cp "$HARNESS_ROOT/scripts/record-harness-event.sh" "$hook_root/scripts/"
cp "$HARNESS_ROOT/scripts/record-permission-outcome.sh" "$hook_root/scripts/"
cp "$HARNESS_ROOT/scripts/verify-harness.sh" "$hook_root/scripts/"
cp "$HARNESS_ROOT/scripts/run-verification-profile.sh" "$hook_root/scripts/"
cp "$HARNESS_ROOT/scripts/lib/specs-state.sh" "$hook_root/scripts/lib/"
cp "$HARNESS_ROOT/scripts/lib/changed-files.sh" "$hook_root/scripts/lib/"
printf '%s\n' '---' 'status: active' '---' 'project: fixture' \
  > "$hook_root/docs/specs/00_PROJECT_FACTS.md"
printf 'private-area/\n' > "$hook_root/docs/specs/dangerous-zones.txt"
printf 'exit 9\n' > "$hook_root/docs/specs/verify.cmd"
git -C "$hook_root" init -q
git -C "$hook_root" add .
git -C "$hook_root" \
  -c user.name=Harness \
  -c user.email=harness@example.invalid \
  commit -qm "fixture baseline"

(
  cd "$hook_root" &&
    printf '%s' '{"hook_event_name":"PreToolUse","permission_mode":"default","tool_name":"Bash","tool_input":{"command":"rm -rf ./cache"}}' |
      bash .claude/hooks/block-dangerous-commands.sh
) >/dev/null 2>&1
(
  cd "$hook_root" &&
    printf '%s' '{"hook_event_name":"PostToolUse","permission_mode":"acceptEdits","tool_name":"Write","tool_use_id":"toolu_stage4","tool_input":{"file_path":"private-area/approved.ts","content":"raw-approved-content"},"tool_response":{"success":true}}' |
      bash scripts/record-permission-outcome.sh claude
) >/dev/null 2>&1
(
  cd "$hook_root" &&
    printf '%s' '{"hook_event_name":"PostToolUse","permission_mode":"bypassPermissions","tool_name":"Bash","tool_use_id":"call_stage4","tool_input":{"command":"rm -rf /raw-bypass-command"},"tool_response":{"exit_code":0}}' |
      bash scripts/record-permission-outcome.sh codex
) >/dev/null 2>&1
(
  cd "$hook_root" &&
    printf '%s' '{"hook_event_name":"PostToolUse","permission_mode":"default","tool_name":"Write","tool_use_id":"toolu_manual","tool_input":{"file_path":"private-area/manual.ts","content":"manual-content"},"tool_response":{"success":true}}' |
      bash scripts/record-permission-outcome.sh claude
) >/dev/null 2>&1
(
  cd "$hook_root" &&
    printf '%s' '{"hook_event_name":"PreToolUse","permission_mode":"acceptEdits","tool_name":"Write","tool_use_id":"toolu_pending","tool_input":{"file_path":"private-area/pending.ts","content":"pending-content"}}' |
      bash scripts/record-permission-outcome.sh claude
) >/dev/null 2>&1
(
  cd "$hook_root" &&
    printf '%s' '{"tool_input":{"file_path":"private-area/config.ts"}}' |
      bash .claude/hooks/guard-dangerous-zones.sh
) >/dev/null 2>&1
patch_input='{"tool_input":{"patch":"*** Begin Patch\n*** Update File: private-area/config.ts\n*** End Patch"}}'
(
  cd "$hook_root" &&
    printf '%s' "$patch_input" |
      bash .codex/hooks/guard-dangerous-zones.sh
) >/dev/null 2>&1
(
  cd "$hook_root" &&
    printf '%s' '{"stop_hook_active":false}' |
      bash .claude/hooks/verify-before-stop.sh
) >/dev/null 2>&1
(
  cd "$hook_root" &&
    printf '%s' '{"stop_hook_active":false}' |
      bash .codex/hooks/verify-before-stop.sh
) >/dev/null 2>&1

hook_events_file="$(git -C "$hook_root" rev-parse --absolute-git-dir)/harness/events.jsonl"
if [ -f "$hook_events_file" ]; then
  hook_events=$(cat "$hook_events_file")
else
  hook_events=""
fi
for expected_category in \
  explicit_approval explicit_bypass destructive_operation dangerous_zone verification_failed; do
  category_count=$(
    printf '%s\n' "$hook_events" |
      jq -s --arg category "$expected_category" \
        '[.[] | select(.category == $category)] | length' 2>/dev/null
  )
  expected_count=1
  case "$expected_category" in
    dangerous_zone|verification_failed) expected_count=2 ;;
  esac
  if [ "${category_count:-0}" -eq "$expected_count" ]; then
    pass "hooks record $expected_category events"
  else
    fail "hooks record $expected_category events"
  fi
done
assert_not_contains "$hook_events" "rm -rf" "hook audit events exclude full shell commands"
assert_not_contains "$hook_events" "private-area/config.ts" "hook audit events exclude file paths"
assert_not_contains "$hook_events" "raw-approved-content" "permission audit events exclude file contents"
assert_not_contains "$hook_events" "manual-content" "default-mode tools do not leak into permission audit"

assert_contains \
  "$(cat "$HARNESS_ROOT/.claude/settings.json")" \
  "record-permission-outcome.sh claude" \
  "Claude registers the real PostToolUse permission outcome hook"
assert_contains \
  "$(cat "$HARNESS_ROOT/.codex/config.toml")" \
  "record-permission-outcome.sh codex" \
  "Codex registers the real PostToolUse permission outcome hook"

# Readiness failure is a distinct audit category.
readiness_root="$FIXTURE_ROOT/readiness"
mkdir -p "$readiness_root/scripts/lib"
cp "$HARNESS_ROOT/scripts/record-harness-event.sh" "$readiness_root/scripts/"
cp "$HARNESS_ROOT/scripts/verify-harness.sh" "$readiness_root/scripts/"
cp "$HARNESS_ROOT/scripts/run-verification-profile.sh" "$readiness_root/scripts/"
cp "$HARNESS_ROOT/scripts/lib/specs-state.sh" "$readiness_root/scripts/lib/"
git -C "$readiness_root" init -q
(
  cd "$readiness_root" &&
    bash scripts/verify-harness.sh --project
) >/dev/null 2>&1
readiness_exit=$?
if [ "$readiness_exit" -ne 0 ]; then
  pass "missing specs still block project verification"
else
  fail "missing specs still block project verification"
fi
readiness_events_file="$(git -C "$readiness_root" rev-parse --absolute-git-dir)/harness/events.jsonl"
readiness_category=$(
  jq -sr 'last.category // empty' "$readiness_events_file" 2>/dev/null
)
assert_eq "specs_missing" "$readiness_category" "readiness failures are recorded separately"

finish_tests
