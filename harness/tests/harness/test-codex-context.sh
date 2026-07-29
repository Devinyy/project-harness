#!/bin/bash
set -u

TEST_DIR=$(cd "$(dirname "$0")" && pwd -P)
HARNESS_ROOT=$(cd "$TEST_DIR/../.." && pwd -P)
. "$TEST_DIR/testlib.sh"

configured_limit=$(sed -n 's/^project_doc_max_bytes = \([0-9][0-9]*\)$/\1/p' "$HARNESS_ROOT/.codex/config.toml")
agents_bytes=$(wc -c < "$HARNESS_ROOT/AGENTS.md" | tr -d ' ')

assert_eq "8192" "$configured_limit" "Codex project document limit is explicit"
if [ "$agents_bytes" -le "${configured_limit:-0}" ]; then
  pass "AGENTS.md fits inside Codex project document limit"
else
  fail "AGENTS.md fits inside Codex project document limit (bytes=$agents_bytes limit=${configured_limit:-missing})"
fi

finish_tests
