#!/bin/bash

TEST_COUNT=0
FAILURE_COUNT=0

pass() {
  TEST_COUNT=$((TEST_COUNT + 1))
  printf 'ok %s - %s\n' "$TEST_COUNT" "$1"
}

fail() {
  TEST_COUNT=$((TEST_COUNT + 1))
  FAILURE_COUNT=$((FAILURE_COUNT + 1))
  printf 'not ok %s - %s\n' "$TEST_COUNT" "$1" >&2
}

assert_eq() {
  local expected="$1"
  local actual="$2"
  local label="$3"
  if [ "$expected" = "$actual" ]; then
    pass "$label"
  else
    fail "$label (expected=$expected actual=$actual)"
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local label="$3"
  if printf '%s' "$haystack" | grep -qF "$needle"; then
    pass "$label"
  else
    fail "$label (missing=$needle)"
  fi
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  local label="$3"
  if printf '%s' "$haystack" | grep -qF "$needle"; then
    fail "$label (unexpected=$needle)"
  else
    pass "$label"
  fi
}

finish_tests() {
  if [ "$FAILURE_COUNT" -ne 0 ]; then
    printf '%s/%s assertions failed\n' "$FAILURE_COUNT" "$TEST_COUNT" >&2
    exit 1
  fi
  printf '%s assertions passed\n' "$TEST_COUNT"
}
