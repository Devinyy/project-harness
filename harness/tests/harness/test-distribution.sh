#!/bin/bash
set -u

TEST_DIR=$(cd "$(dirname "$0")" && pwd -P)
HARNESS_ROOT=$(cd "$TEST_DIR/../.." && pwd -P)
. "$TEST_DIR/testlib.sh"

PACKAGE_SCRIPT="$HARNESS_ROOT/scripts/package-harness.sh"
archive_rel="project-harness-2.0.0.tar.gz"
FIXTURE_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/harness-distribution.XXXXXX")
trap 'rm -rf "$FIXTURE_ROOT"' EXIT

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

assert_file() {
  local root="$1"
  local rel="$2"
  local label="$3"
  if [ -f "$root/$rel" ]; then
    pass "$label"
  else
    fail "$label (missing=$rel)"
  fi
}

assert_dir() {
  local root="$1"
  local rel="$2"
  local label="$3"
  if [ -d "$root/$rel" ]; then
    pass "$label"
  else
    fail "$label (missing=$rel)"
  fi
}

assert_no_path() {
  local root="$1"
  local rel="$2"
  local label="$3"
  if [ ! -e "$root/$rel" ]; then
    pass "$label"
  else
    fail "$label (unexpected=$rel)"
  fi
}

run_package() {
  local output_dir="$1"
  (
    cd "$HARNESS_ROOT" &&
      bash "$PACKAGE_SCRIPT" --output "$output_dir"
  )
}

if [ ! -f "$PACKAGE_SCRIPT" ]; then
  fail "deterministic package CLI exists"
  finish_tests
  exit 0
fi
pass "deterministic package CLI exists"

help_root="$FIXTURE_ROOT/help-output"
help_output=$(cd "$HARNESS_ROOT" && bash "$PACKAGE_SCRIPT" --help 2>&1)
help_exit=$?
assert_eq "0" "$help_exit" "--help exits successfully"
if printf '%s' "$help_output" | grep -qF -- "--output"; then
  pass "--help documents output"
else
  fail "--help documents output"
fi
assert_no_path "$FIXTURE_ROOT" "help-output" "--help performs no output write"

run_builder_for_fixture() {
  local source_root="$1"
  local output_dir="$2"
  python3 "$HARNESS_ROOT/scripts/lib/package_harness.py" \
    --root "$source_root" --output "$output_dir"
}

run_nested_output_case() {
  local case_name="$1"
  local output_rel="$2"
  local source_root="$FIXTURE_ROOT/nested-output-$case_name/source"
  local output_dir="$source_root/$output_rel"
  local output_log
  local output_exit
  mkdir -p "$source_root"
  cp -R "$HARNESS_ROOT/." "$source_root/"
  output_log=$(run_builder_for_fixture "$source_root" "$output_dir" 2>&1)
  output_exit=$?
  if [ "$output_exit" -ne 0 ]; then
    pass "source-tree output is rejected: $case_name"
  else
    fail "source-tree output is rejected: $case_name"
  fi
  assert_contains "$output_log" "source tree" "source-tree output explains the boundary: $case_name"
  assert_no_path "$output_dir" "$archive_rel" "source-tree output writes no archive: $case_name"
  assert_no_path "$output_dir" "$archive_rel.sha256" "source-tree output writes no checksum: $case_name"
}

run_nested_output_case distribution distribution
run_nested_output_case root .
run_nested_output_case nested build/nested-output

allowed_parent="$FIXTURE_ROOT/allowed-parent"
allowed_source="$allowed_parent/source"
mkdir -p "$allowed_source"
cp -R "$HARNESS_ROOT/." "$allowed_source/"
allowed_log=$(run_builder_for_fixture "$allowed_source" "$allowed_parent" 2>&1)
allowed_exit=$?
assert_eq "0" "$allowed_exit" "output in a source-external parent succeeds"
assert_file "$allowed_parent" "$archive_rel" "source-external parent receives the archive"
assert_not_contains "$allowed_log" "source tree" "source-external parent is not rejected"

empty_manifest_root="$FIXTURE_ROOT/empty-manifest-source"
empty_manifest_output="$FIXTURE_ROOT/empty-manifest-output"
mkdir -p "$empty_manifest_root" "$empty_manifest_output"
cp -R "$HARNESS_ROOT/." "$empty_manifest_root/"
printf '%s\n' '# no source entries' > "$empty_manifest_root/distribution/MANIFEST.txt"
empty_manifest_log=$(run_builder_for_fixture "$empty_manifest_root" "$empty_manifest_output" 2>&1)
empty_manifest_exit=$?
if [ "$empty_manifest_exit" -ne 0 ]; then
  pass "empty manifest is rejected"
else
  fail "empty manifest is rejected"
fi
assert_contains "$empty_manifest_log" "empty" "empty manifest rejection explains the error"
assert_no_path "$empty_manifest_output" "$archive_rel" "empty manifest failure writes no archive"

bad_manifest_root="$FIXTURE_ROOT/bad-manifest-source"
bad_manifest_output="$FIXTURE_ROOT/bad-manifest-output"
mkdir -p "$bad_manifest_root" "$bad_manifest_output"
cp -R "$HARNESS_ROOT/." "$bad_manifest_root/"
printf '%s\n' 'scripts/' 'scripts/' > "$bad_manifest_root/distribution/MANIFEST.txt"
bad_manifest_log=$(run_builder_for_fixture "$bad_manifest_root" "$bad_manifest_output" 2>&1)
bad_manifest_exit=$?
if [ "$bad_manifest_exit" -ne 0 ]; then
  pass "duplicate manifest entries are rejected"
else
  fail "duplicate manifest entries are rejected"
fi
assert_contains "$bad_manifest_log" "duplicate" "duplicate manifest rejection explains the error"
assert_no_path "$bad_manifest_output" "$archive_rel" "duplicate manifest failure writes no archive"

case_manifest_root="$FIXTURE_ROOT/case-manifest-source"
case_manifest_output="$FIXTURE_ROOT/case-manifest-output"
mkdir -p "$case_manifest_root" "$case_manifest_output"
cp -R "$HARNESS_ROOT/." "$case_manifest_root/"
printf '%s\n' 'SCRIPTS/' >> "$case_manifest_root/distribution/MANIFEST.txt"
case_manifest_log=$(run_builder_for_fixture "$case_manifest_root" "$case_manifest_output" 2>&1)
case_manifest_exit=$?
if [ "$case_manifest_exit" -ne 0 ]; then
  pass "case-conflicting manifest entries are rejected"
else
  fail "case-conflicting manifest entries are rejected"
fi
assert_contains "$case_manifest_log" "case conflict" "case-conflicting manifest rejection explains the error"
assert_no_path "$case_manifest_output" "$archive_rel" "case-conflicting manifest failure writes no archive"

missing_source_root="$FIXTURE_ROOT/missing-source-source"
missing_source_output="$FIXTURE_ROOT/missing-source-output"
mkdir -p "$missing_source_root" "$missing_source_output"
cp -R "$HARNESS_ROOT/." "$missing_source_root/"
rm "$missing_source_root/README.md"
missing_source_log=$(run_builder_for_fixture "$missing_source_root" "$missing_source_output" 2>&1)
missing_source_exit=$?
if [ "$missing_source_exit" -ne 0 ]; then
  pass "missing manifest source is rejected"
else
  fail "missing manifest source is rejected"
fi
assert_contains "$missing_source_log" "missing" "missing source rejection explains the error"
assert_no_path "$missing_source_output" "$archive_rel" "missing source failure writes no archive"

symlink_source_root="$FIXTURE_ROOT/symlink-source"
symlink_source_output="$FIXTURE_ROOT/symlink-output"
mkdir -p "$symlink_source_root" "$symlink_source_output"
cp -R "$HARNESS_ROOT/." "$symlink_source_root/"
ln -s README.md "$symlink_source_root/scripts/readme-link"
symlink_log=$(run_builder_for_fixture "$symlink_source_root" "$symlink_source_output" 2>&1)
symlink_exit=$?
if [ "$symlink_exit" -ne 0 ]; then
  pass "manifest symlink is rejected"
else
  fail "manifest symlink is rejected"
fi
assert_contains "$symlink_log" "symlink" "symlink rejection explains the error"
assert_no_path "$symlink_source_output" "$archive_rel" "symlink failure writes no archive"

unsafe_manifest_root="$FIXTURE_ROOT/unsafe-manifest-source"
unsafe_manifest_output="$FIXTURE_ROOT/unsafe-manifest-output"
mkdir -p "$unsafe_manifest_root" "$unsafe_manifest_output"
cp -R "$HARNESS_ROOT/." "$unsafe_manifest_root/"
printf '%s\n' '../escape' > "$unsafe_manifest_root/distribution/MANIFEST.txt"
unsafe_manifest_log=$(run_builder_for_fixture "$unsafe_manifest_root" "$unsafe_manifest_output" 2>&1)
unsafe_manifest_exit=$?
if [ "$unsafe_manifest_exit" -ne 0 ]; then
  pass "unsafe manifest path is rejected"
else
  fail "unsafe manifest path is rejected"
fi
assert_contains "$unsafe_manifest_log" "unsafe" "unsafe manifest rejection explains the error"
assert_no_path "$unsafe_manifest_output" "$archive_rel" "unsafe manifest failure writes no archive"

invalid_version_root="$FIXTURE_ROOT/invalid-version-source"
invalid_version_output="$FIXTURE_ROOT/invalid-version-output"
mkdir -p "$invalid_version_root" "$invalid_version_output"
cp -R "$HARNESS_ROOT/." "$invalid_version_root/"
printf '%s\n' '2.0' > "$invalid_version_root/VERSION"
invalid_version_log=$(run_builder_for_fixture "$invalid_version_root" "$invalid_version_output" 2>&1)
invalid_version_exit=$?
if [ "$invalid_version_exit" -ne 0 ]; then
  pass "invalid VERSION is rejected"
else
  fail "invalid VERSION is rejected"
fi
assert_contains "$invalid_version_log" "invalid VERSION" "invalid VERSION rejection explains the error"
assert_no_path "$invalid_version_output" "$archive_rel" "invalid VERSION failure writes no archive"

leak_source_root="$FIXTURE_ROOT/leak-source"
leak_output="$FIXTURE_ROOT/leak-output"
mkdir -p "$leak_source_root" "$leak_output" "$leak_source_root/scripts/lib/__pycache__"
cp -R "$HARNESS_ROOT/." "$leak_source_root/"
printf '%s\n' 'local setting' > "$leak_source_root/.claude/settings.local.json"
printf '%s\n' 'local config' > "$leak_source_root/.codex/config.local.toml"
printf '%s\n' 'dotenv' > "$leak_source_root/scripts/.env"
printf '%s\n' 'private key' > "$leak_source_root/scripts/lib/private.pem"
printf '%s\n' 'bytecode' > "$leak_source_root/scripts/lib/__pycache__/package_harness.pyc"
printf '%s\n' 'generated map' > "$leak_source_root/scripts/PROJECT_MAP.md"
leak_log=$(run_builder_for_fixture "$leak_source_root" "$leak_output" 2>&1)
leak_exit=$?
assert_eq "0" "$leak_exit" "denylisted source files do not block packaging"
leak_listing=$(tar -tzf "$leak_output/$archive_rel" 2>/dev/null || true)
if printf '%s\n' "$leak_listing" | grep -Eiq 'settings\.local|config\.local|(^|/)\.env$|private\.pem|__pycache__|\.pyc$|PROJECT_MAP\.md'; then
  fail "archive excludes denylisted generated and credential files"
else
  pass "archive excludes denylisted generated and credential files"
fi

first_output="$FIXTURE_ROOT/first"
second_output="$FIXTURE_ROOT/second"
mkdir -p "$first_output" "$second_output"
source_manifest_before=$(sha256_file "$HARNESS_ROOT/distribution/MANIFEST.txt")
source_builder_before=$(sha256_file "$HARNESS_ROOT/scripts/lib/package_harness.py")
first_output_log=$(run_package "$first_output" 2>&1)
first_exit=$?
assert_eq "0" "$first_exit" "package build succeeds"
assert_contains "$first_output_log" "project-harness-2.0.0" "build reports the fixed archive name"
assert_eq "$source_manifest_before" "$(sha256_file "$HARNESS_ROOT/distribution/MANIFEST.txt")" "package build preserves the source allowlist"
assert_eq "$source_builder_before" "$(sha256_file "$HARNESS_ROOT/scripts/lib/package_harness.py")" "package build preserves the source builder"

checksum_rel="$archive_rel.sha256"
archive_one="$first_output/$archive_rel"
checksum_one="$first_output/$checksum_rel"
assert_file "$first_output" "$archive_rel" "archive is written"
assert_file "$first_output" "$checksum_rel" "archive checksum is written"

second_output_log=$(run_package "$second_output" 2>&1)
second_exit=$?
assert_eq "0" "$second_exit" "same-source second package build succeeds"
assert_file "$second_output" "$archive_rel" "second archive is written"
if cmp -s "$archive_one" "$second_output/$archive_rel"; then
  pass "same-source archives are byte-identical"
else
  fail "same-source archives are byte-identical"
fi
assert_eq "$(cat "$checksum_one")" "$(cat "$second_output/$checksum_rel")" "same-source checksums are identical"
assert_eq "$(sha256_file "$archive_one")" "$(awk '{print $1}' "$checksum_one")" "checksum covers the archive bytes"

archive_listing=$(tar -tzf "$archive_one")
assert_contains "$archive_listing" "project-harness-2.0.0/ARCHIVE_MANIFEST.tsv" "archive contains the explicit file manifest"
assert_contains "$archive_listing" "project-harness-2.0.0/scripts/package-harness.sh" "archive contains the packaging CLI"
assert_contains "$archive_listing" "project-harness-2.0.0/scripts/lib/package_harness.py" "archive contains the Python builder"
assert_contains "$archive_listing" "project-harness-2.0.0/distribution/MANIFEST.txt" "archive contains the source allowlist"
assert_contains "$archive_listing" "project-harness-2.0.0/VERSION" "archive contains VERSION"
assert_contains "$archive_listing" "project-harness-2.0.0/LICENSE" "archive contains LICENSE"
assert_contains "$archive_listing" "project-harness-2.0.0/.gitattributes" "archive contains .gitattributes"
for required_dir in .claude .codex .cursor scripts tests spec-templates token-templates project-templates docs/harness; do
  assert_contains "$archive_listing" "project-harness-2.0.0/$required_dir/" "archive contains $required_dir"
done

if printf '%s\n' "$archive_listing" | grep -Eq '(^|/)(docs/specs|docs/token-specs|PROJECT_MAP\.md|docs/superpowers|\.git|\.DS_Store)(/|$)'; then
  fail "archive excludes project state and internal process files"
else
  pass "archive excludes project state and internal process files"
fi
if printf '%s\n' "$archive_listing" | grep -Eiq '(^|/)(settings\.local\.json|config\.local\.toml|\.env|credentials?[^/]*)$'; then
  fail "archive excludes personal and credential files"
else
  pass "archive excludes personal and credential files"
fi
if printf '%s\n' "$archive_listing" | grep -Eq '(^|/)\.\.?(/|$)|(^|/)\.\./'; then
  fail "archive paths have no traversal components"
else
  pass "archive paths have no traversal components"
fi

unpack_root="$FIXTURE_ROOT/unpacked"
mkdir -p "$unpack_root"
tar -xzf "$archive_one" -C "$unpack_root"
package_root="$unpack_root/project-harness-2.0.0"
assert_dir "$unpack_root" "project-harness-2.0.0" "archive extracts to the required top-level directory"

manifest_check=$(python3 - "$package_root" <<'PY'
import hashlib
import os
import stat
import sys

root = sys.argv[1]
manifest_path = os.path.join(root, "ARCHIVE_MANIFEST.tsv")
seen = set()
with open(manifest_path, "r", encoding="utf-8", newline="") as handle:
    rows = [line.rstrip("\n") for line in handle if line.strip()]
for row in rows:
    fields = row.split("\t")
    if len(fields) != 3:
        raise SystemExit("manifest row is not path<TAB>mode<TAB>sha256")
    rel, mode_text, expected = fields
    if rel == "ARCHIVE_MANIFEST.tsv" or rel in seen:
        raise SystemExit("manifest includes itself or duplicates a path")
    seen.add(rel)
    if os.path.isabs(rel) or ".." in rel.split("/"):
        raise SystemExit("manifest contains an unsafe path")
    path = os.path.join(root, rel)
    if not os.path.isfile(path) or os.path.islink(path):
        raise SystemExit("manifest path is not a regular file: " + rel)
    actual_mode = stat.S_IMODE(os.stat(path, follow_symlinks=False).st_mode)
    if mode_text != format(actual_mode, "04o"):
        raise SystemExit("mode mismatch: " + rel)
    with open(path, "rb") as source:
        actual = hashlib.sha256(source.read()).hexdigest()
    if actual != expected:
        raise SystemExit("hash mismatch: " + rel)
all_files = set()
for current, dirs, files in os.walk(root):
    dirs[:] = sorted(dirs)
    for name in sorted(files):
        rel = os.path.relpath(os.path.join(current, name), root)
        if rel != "ARCHIVE_MANIFEST.tsv":
            all_files.add(rel)
if all_files != seen:
    raise SystemExit("manifest does not cover exactly the archive files")
print("ok")
PY
)
manifest_exit=$?
assert_eq "0" "$manifest_exit" "archive manifest covers extracted files and modes"
assert_eq "ok" "$manifest_check" "archive manifest content validates"

if [ -x "$package_root/scripts/package-harness.sh" ]; then
  pass "packaging CLI keeps executable permission"
else
  fail "packaging CLI keeps executable permission"
fi
if [ -x "$package_root/scripts/doctor.sh" ]; then
  pass "doctor keeps executable permission"
else
  fail "doctor keeps executable permission"
fi

doctor_output=$(cd "$package_root" && bash scripts/doctor.sh --self --strict 2>&1)
doctor_exit=$?
assert_eq "0" "$doctor_exit" "unpacked package passes strict self doctor"
assert_contains "$doctor_output" "harness" "strict self doctor reports harness mode"

repack_output="$FIXTURE_ROOT/repack"
mkdir -p "$repack_output"
(
  cd "$package_root" &&
    bash scripts/package-harness.sh --output "$repack_output"
) >/dev/null 2>&1
repack_exit=$?
assert_eq "0" "$repack_exit" "unpacked package can be packaged without git"
if cmp -s "$archive_one" "$repack_output/$archive_rel"; then
  pass "unpacked package reproduces the same archive bytes"
else
  fail "unpacked package reproduces the same archive bytes"
fi

knowledge_root="$FIXTURE_ROOT/knowledge"
mkdir -p "$knowledge_root"
run_knowledge() {
  (
    cd "$knowledge_root" &&
      bash "$package_root/scripts/init-project-knowledge.sh" "$@"
  )
}
run_knowledge --domain harness >/dev/null 2>&1
assert_eq "0" "$?" "knowledge harness domain initializes"
run_knowledge --domain requirements --module orders >/dev/null 2>&1
assert_eq "0" "$?" "knowledge requirements module initializes"
run_knowledge --domain experience --case keyboard-focus >/dev/null 2>&1
assert_eq "0" "$?" "knowledge experience case initializes"
run_knowledge --domain all >/dev/null 2>&1
assert_eq "0" "$?" "knowledge all domain initializes"
assert_file "$knowledge_root" "PROJECT_MAP.md" "knowledge PROJECT_MAP exists"
assert_contains "$(cat "$knowledge_root/PROJECT_MAP.md")" "status: draft" "knowledge PROJECT_MAP starts as draft"
assert_contains "$(cat "$knowledge_root/PROJECT_MAP.md")" "项目资料登记" "knowledge PROJECT_MAP has the registration heading"
assert_contains "$(cat "$knowledge_root/PROJECT_MAP.md")" "./harness/MAP.md" "knowledge PROJECT_MAP reaches harness"
assert_contains "$(cat "$knowledge_root/PROJECT_MAP.md")" "./badcase/MAP.md" "knowledge PROJECT_MAP reaches badcase"
assert_file "$knowledge_root" "harness/MAP.md" "knowledge harness MAP exists"
assert_file "$knowledge_root" "requirements/modules/orders.md" "knowledge module exists"
assert_file "$knowledge_root" "badcase/keyboard-focus.md" "knowledge case exists"
assert_contains "$(cat "$knowledge_root/requirements/modules/orders.md")" "status: draft" "generated module remains draft"
assert_contains "$(cat "$knowledge_root/badcase/keyboard-focus.md")" "status: draft" "generated case remains draft"
assert_no_path "$knowledge_root" "docs/specs" "knowledge initialization does not create business specs"
assert_no_path "$knowledge_root" "docs/token-specs" "knowledge initialization does not create business tokens"

for flavor in pc mini; do
  flavor_root="$FIXTURE_ROOT/flavor-$flavor"
  mkdir -p "$flavor_root"
  cp -R "$package_root/." "$flavor_root/"
  (
    cd "$flavor_root" &&
      bash scripts/init-specs.sh --flavor "$flavor"
  ) >/dev/null 2>&1
  flavor_exit=$?
  assert_eq "0" "$flavor_exit" "$flavor specs initialization succeeds: $flavor"
  assert_file "$flavor_root" "docs/specs/00_PROJECT_FACTS.md" "$flavor facts skeleton exists: $flavor"
  assert_not_contains "$(cat "$flavor_root/docs/specs/00_PROJECT_FACTS.md")" "status: active" "$flavor facts is not falsely active: $flavor"
done

upgrade_root="$FIXTURE_ROOT/upgrade"
mkdir -p "$upgrade_root"
cp -R "$package_root/." "$upgrade_root/"
mkdir -p "$upgrade_root/custom-domain/docs/specs" "$upgrade_root/docs/token-specs"
printf '%s\n' '# user project map' > "$upgrade_root/PROJECT_MAP.md"
printf '%s\n' '# user domain' > "$upgrade_root/custom-domain/README.md"
printf '%s\n' '# user fact' > "$upgrade_root/custom-domain/docs/specs/00_PROJECT_FACTS.md"
printf '%s\n' '{"user":true}' > "$upgrade_root/docs/token-specs/user.json"
for entry in .claude/ .codex/ .cursor/ scripts/ tests/ spec-templates/ token-templates/ project-templates/ docs/harness/ .windsurfrules AGENTS.md CLAUDE.md MAP.md README.md CHANGELOG.md VERSION LICENSE .gitattributes distribution/; do
  source="$package_root/$entry"
  target="$upgrade_root/$entry"
  if [ -d "$source" ]; then
    mkdir -p "$target"
    cp -R "$source/." "$target/"
  else
    mkdir -p "$(dirname "$target")"
    cp "$source" "$target"
  fi
done
assert_contains "$(cat "$upgrade_root/PROJECT_MAP.md")" "user project map" "upgrade preserves PROJECT_MAP"
assert_contains "$(cat "$upgrade_root/custom-domain/README.md")" "user domain" "upgrade preserves user domain"
assert_contains "$(cat "$upgrade_root/custom-domain/docs/specs/00_PROJECT_FACTS.md")" "user fact" "upgrade preserves user specs"
assert_contains "$(cat "$upgrade_root/docs/token-specs/user.json")" '"user":true' "upgrade preserves user tokens"

# The package test intentionally invokes focused commands above; it must not
# recurse through tests/harness/run.sh while validating the unpacked package.
if grep -Fq 'tests/harness/run.sh' "$PACKAGE_SCRIPT" 2>/dev/null; then
  fail "distribution build does not recursively execute the full test suite"
else
  pass "distribution build does not recursively execute the full test suite"
fi

finish_tests
