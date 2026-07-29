#!/bin/bash
set -u

TEST_DIR=$(cd "$(dirname "$0")" && pwd -P)
HARNESS_ROOT=$(cd "$TEST_DIR/../.." && pwd -P)
. "$TEST_DIR/testlib.sh"

FIXTURE_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/harness-changed-files.XXXXXX")
trap 'rm -rf "$FIXTURE_ROOT"' EXIT

git -C "$FIXTURE_ROOT" init -q
mkdir -p "$FIXTURE_ROOT/src" "$FIXTURE_ROOT/apps/micro-main/src"
printf 'ignored.ts\n' > "$FIXTURE_ROOT/.gitignore"
printf 'base\n' > "$FIXTURE_ROOT/src/staged.ts"
printf 'base\n' > "$FIXTURE_ROOT/src/unstaged.ts"
printf 'base\n' > "$FIXTURE_ROOT/src/both.ts"
printf 'base\n' > "$FIXTURE_ROOT/src/clean.ts"
git -C "$FIXTURE_ROOT" add .
git -C "$FIXTURE_ROOT" \
  -c user.name=Harness \
  -c user.email=harness@example.invalid \
  commit -qm "fixture baseline"

printf 'staged\n' > "$FIXTURE_ROOT/src/staged.ts"
git -C "$FIXTURE_ROOT" add src/staged.ts
printf 'unstaged\n' > "$FIXTURE_ROOT/src/unstaged.ts"
printf 'staged\n' > "$FIXTURE_ROOT/src/both.ts"
git -C "$FIXTURE_ROOT" add src/both.ts
printf 'unstaged too\n' >> "$FIXTURE_ROOT/src/both.ts"
printf 'untracked dangerous\n' > "$FIXTURE_ROOT/apps/micro-main/src/untracked.ts"
printf 'ignored\n' > "$FIXTURE_ROOT/ignored.ts"

CHANGED_FILES_LIB="$HARNESS_ROOT/scripts/lib/changed-files.sh"
if [ ! -f "$CHANGED_FILES_LIB" ]; then
  fail "changed-files helper exists"
  finish_tests
  exit 1
fi

. "$CHANGED_FILES_LIB"
actual=$(changed_files "$FIXTURE_ROOT")
expected=$(printf '%s\n' \
  'apps/micro-main/src/untracked.ts' \
  'src/both.ts' \
  'src/staged.ts' \
  'src/unstaged.ts')

assert_eq "$expected" "$actual" "changed_files returns staged, unstaged, and untracked files once"
assert_not_contains "$actual" "src/clean.ts" "changed_files excludes clean files"
assert_not_contains "$actual" "ignored.ts" "changed_files excludes ignored files"
both_count=$(printf '%s\n' "$actual" | grep -c '^src/both\.ts$')
assert_eq "1" "$both_count" "changed_files de-duplicates staged and unstaged paths"

finish_tests
