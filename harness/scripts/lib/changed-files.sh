#!/bin/bash

changed_files() {
  local git_root="${1:-.}"

  if ! git -C "$git_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    return 0
  fi

  {
    if git -C "$git_root" rev-parse --verify HEAD >/dev/null 2>&1; then
      git -C "$git_root" diff --name-only HEAD
    else
      git -C "$git_root" diff --name-only --cached
    fi
    git -C "$git_root" ls-files --others --exclude-standard
  } | LC_ALL=C sort -u
}
