#!/bin/bash
set -euo pipefail

TEST_DIR=$(cd "$(dirname "$0")" && pwd -P)

for test_file in "$TEST_DIR"/test-*.sh; do
  [ "$(basename "$test_file")" = "testlib.sh" ] && continue
  printf '== %s ==\n' "$(basename "$test_file")"
  bash "$test_file"
done
