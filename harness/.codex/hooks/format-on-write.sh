#!/bin/bash
# Codex PostToolUse hook: 格式化所有已变更的受支持文件

cat >/dev/null

HOOK_DIR=$(cd "$(dirname "$0")" && pwd -P)
HARNESS_ROOT=$(cd "$HOOK_DIR/../.." && pwd -P)
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd -P)
. "$HARNESS_ROOT/scripts/lib/changed-files.sh"

CHANGED_FILES=$(
  changed_files "$REPO_ROOT" |
    grep -E '\.(vue|ts|js|css|less|scss|json)$' || true
)
if [ -n "$CHANGED_FILES" ]; then
  (
    cd "$REPO_ROOT" &&
      printf '%s\n' "$CHANGED_FILES" |
        xargs pnpm exec prettier --write 2>/dev/null
  ) || true
fi

echo '{"continue": true}'
exit 0
