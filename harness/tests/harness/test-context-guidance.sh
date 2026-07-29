#!/bin/bash
set -u

TEST_DIR=$(cd "$(dirname "$0")" && pwd -P)
HARNESS_ROOT=$(cd "$TEST_DIR/../.." && pwd -P)
. "$TEST_DIR/testlib.sh"

for relative_path in \
  AGENTS.md \
  CLAUDE.md \
  .cursor/rules/project-harness.mdc \
  .windsurfrules \
  README.md; do
  content=$(sed -n '1,140p' "$HARNESS_ROOT/$relative_path")
  assert_contains "$content" "active" "$relative_path requires active specs"
  assert_contains "$content" "draft" "$relative_path explains draft specs"
done

finish_tests
