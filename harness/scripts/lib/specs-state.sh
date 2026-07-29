#!/bin/bash

specs_state() {
  local project_root="${1:-.}"
  local specs_dir="$project_root/docs/specs"
  local facts_file="$specs_dir/00_PROJECT_FACTS.md"

  if [ ! -f "$facts_file" ]; then
    printf 'missing\n'
    return 0
  fi

  if grep -rlF \
    -e '<填写' \
    -e '<生成时填写>' \
    -e '<项目名>' \
    "$specs_dir" >/dev/null 2>&1; then
    printf 'draft\n'
    return 0
  fi

  if ! grep -qE '^status:[[:space:]]*active[[:space:]]*$' "$facts_file"; then
    printf 'draft\n'
    return 0
  fi

  if grep -rhE '^status:' "$specs_dir" 2>/dev/null |
    grep -qvE '^status:[[:space:]]*active[[:space:]]*$'; then
    printf 'draft\n'
    return 0
  fi

  printf 'active\n'
}
