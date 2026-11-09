#!/bin/bash
set -u

TEST_DIR=$(cd "$(dirname "$0")" && pwd -P)
HARNESS_ROOT=$(cd "$TEST_DIR/../.." && pwd -P)
. "$TEST_DIR/testlib.sh"

SCRIPT="$HARNESS_ROOT/scripts/init-project-knowledge.sh"
FIXTURE_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/harness-project-knowledge.XXXXXX")
FIXTURE_ROOT=$(cd "$FIXTURE_ROOT" && pwd -P)
trap 'rm -rf "$FIXTURE_ROOT"' EXIT

assert_file() {
  local root="$1"
  local relative_path="$2"
  local label="$3"
  if [ -f "$root/$relative_path" ]; then
    pass "$label"
  else
    fail "$label (missing=$relative_path)"
  fi
}

assert_no_file() {
  local root="$1"
  local relative_path="$2"
  local label="$3"
  if [ ! -e "$root/$relative_path" ]; then
    pass "$label"
  else
    fail "$label (unexpected=$relative_path)"
  fi
}

# Local Markdown links are resolved from the file that owns them.  This keeps
# partial-domain generation honest without trying to validate renderer-specific
# fragment slug rules.
check_local_links() {
  local root="$1"
  local file_path="$2"
  local label_prefix="$3"
  local base_dir
  local link
  local relative_target
  local target_path
  base_dir=$(cd "$(dirname "$file_path")" && pwd -P)
  while IFS= read -r link; do
    relative_target="${link#](}"
    relative_target="${relative_target%)}"
    case "$relative_target" in
      ''|'#'*|'http://'*|'https://'*|'mailto:'*) continue ;;
    esac
    target_path="${relative_target%%#*}"
    [ -n "$target_path" ] || target_path="$(basename "$file_path")"
    if [ -e "$base_dir/$target_path" ]; then
      pass "$label_prefix link resolves: $target_path"
    else
      fail "$label_prefix link resolves: $target_path"
    fi
  done < <(grep -oE '\]\([^)]*\)' "$file_path" 2>/dev/null || true)
}

run_init() {
  local target="$1"
  shift
  (
    cd "$target" &&
      bash "$SCRIPT" "$@"
  )
}

if [ ! -f "$SCRIPT" ]; then
  fail "project knowledge initializer exists"
  finish_tests
  exit 0
fi

# The source manifest is part of the distribution contract.  Keep this test
# useful while templates are being assembled by reporting the missing bundle
# as a normal failing assertion rather than silently skipping all behavior.
assert_file "$HARNESS_ROOT" "project-templates/MANIFEST.tsv" "template manifest exists"
if [ ! -f "$HARNESS_ROOT/project-templates/MANIFEST.tsv" ]; then
  finish_tests
  exit 0
fi

empty_root="$FIXTURE_ROOT/empty"
mkdir -p "$empty_root"
noarg_output=$(run_init "$empty_root" 2>&1)
noarg_exit=$?
assert_eq "0" "$noarg_exit" "no arguments only show usage"
assert_contains "$noarg_output" "domain" "usage explains domain selection"
assert_no_file "$empty_root" "MAP.md" "no arguments do not create root MAP"

dry_root="$FIXTURE_ROOT/dry-run"
mkdir -p "$dry_root"
dry_output=$(run_init "$dry_root" --domain all --dry-run 2>&1)
dry_exit=$?
assert_eq "0" "$dry_exit" "dry-run succeeds for all domains"
assert_contains "$dry_output" "DRY-RUN" "dry-run reports planned work"
assert_no_file "$dry_root" "MAP.md" "dry-run does not create root MAP"
if [ -d "$dry_root" ]; then
  generated_dry_files=$(find "$dry_root" -type f -print | wc -l | tr -d ' ')
  assert_eq "0" "$generated_dry_files" "dry-run does not create files"
fi

invalid_root="$FIXTURE_ROOT/invalid"
mkdir -p "$invalid_root"
invalid_snapshot_before=$(cd "$invalid_root" && find . -print | sed '1d' | sort)
invalid_output=$(run_init "$invalid_root" --domain requirements --module ../escape 2>&1)
invalid_exit=$?
if [ "$invalid_exit" -ne 0 ]; then
  pass "module path traversal is rejected"
else
  fail "module path traversal is rejected"
fi
assert_contains "$invalid_output" "非法" "invalid module reports a useful error"
assert_no_file "$invalid_root" "requirements/escape.md" "rejected module cannot write through a normalized path"
invalid_snapshot_after=$(cd "$invalid_root" && find . -print | sed '1d' | sort)
assert_eq "$invalid_snapshot_before" "$invalid_snapshot_after" "rejected module writes no target files"

missing_value_output=$(run_init "$invalid_root" --domain requirements --module 2>&1)
missing_value_exit=$?
if [ "$missing_value_exit" -ne 0 ]; then
  pass "missing module value is rejected"
else
  fail "missing module value is rejected"
fi
assert_contains "$missing_value_output" "缺少参数值" "missing module value explains the error"

unknown_output=$(run_init "$invalid_root" --domain unknown 2>&1)
unknown_exit=$?
if [ "$unknown_exit" -ne 0 ]; then
  pass "unknown domain is rejected"
else
  fail "unknown domain is rejected"
fi
assert_contains "$unknown_output" "domain" "unknown domain explains the option"

for reserved_name in _module _case MAP map PROJECT_MAP project_map; do
  reserved_root="$FIXTURE_ROOT/reserved-$reserved_name"
  mkdir -p "$reserved_root"
  reserved_output=$(run_init "$reserved_root" --domain requirements --module "$reserved_name" 2>&1)
  reserved_exit=$?
  if [ "$reserved_exit" -ne 0 ]; then
    pass "reserved module name $reserved_name is rejected"
  else
    fail "reserved module name $reserved_name is rejected"
  fi
  assert_contains "$reserved_output" "保留" "reserved module name $reserved_name explains the conflict"
  assert_no_file "$reserved_root" "PROJECT_MAP.md" "reserved module name $reserved_name writes no project map"
done

for reserved_case in _module _case MAP map PROJECT_MAP project_map; do
  reserved_case_root="$FIXTURE_ROOT/reserved-case-$reserved_case"
  mkdir -p "$reserved_case_root"
  reserved_case_output=$(run_init "$reserved_case_root" --domain experience --case "$reserved_case" 2>&1)
  reserved_case_exit=$?
  if [ "$reserved_case_exit" -ne 0 ]; then
    pass "reserved case name $reserved_case is rejected"
  else
    fail "reserved case name $reserved_case is rejected"
  fi
  assert_contains "$reserved_case_output" "保留" "reserved case name $reserved_case explains the conflict"
  assert_no_file "$reserved_case_root" "PROJECT_MAP.md" "reserved case name $reserved_case writes no project map"
done

target_option_root="$FIXTURE_ROOT/target-option"
mkdir -p "$target_option_root"
target_option_output=$(
  cd "$FIXTURE_ROOT" &&
    bash "$SCRIPT" --target "$target_option_root" --domain design 2>&1
)
target_option_exit=$?
assert_eq "0" "$target_option_exit" "explicit target directory generation succeeds"
assert_file "$target_option_root" "PROJECT_MAP.md" "explicit target writes to selected directory"
assert_contains "$target_option_output" "完成" "explicit target reports completion"

target_symlink_parent="$FIXTURE_ROOT/target-symlink-parent"
target_symlink_outside="$FIXTURE_ROOT/target-symlink-outside"
mkdir -p "$target_symlink_parent" "$target_symlink_outside/project"
ln -s "$target_symlink_outside" "$target_symlink_parent/link"
target_symlink_output=$(
  cd "$FIXTURE_ROOT" &&
    bash "$SCRIPT" --target "$target_symlink_parent/link/project" --domain design 2>&1
)
target_symlink_exit=$?
if [ "$target_symlink_exit" -ne 0 ]; then
  pass "explicit target ancestor symlink is rejected"
else
  fail "explicit target ancestor symlink is rejected"
fi
assert_contains "$target_symlink_output" "符号链接" "target ancestor symlink explains the boundary"
assert_no_file "$target_symlink_outside/project" "PROJECT_MAP.md" "target ancestor symlink writes no outside project map"

development_fixture_repo="$FIXTURE_ROOT/development-checkout"
development_fixture_harness="$development_fixture_repo/harness"
mkdir -p "$development_fixture_harness/scripts/lib" "$development_fixture_harness/docs/superpowers"
cp "$SCRIPT" "$development_fixture_harness/scripts/init-project-knowledge.sh"
cp "$HARNESS_ROOT/scripts/doctor.sh" "$development_fixture_harness/scripts/doctor.sh"
cp "$HARNESS_ROOT/scripts/lib/knowledge-manifest.sh" "$development_fixture_harness/scripts/lib/"
cp -R "$HARNESS_ROOT/project-templates" "$development_fixture_harness/"
git -C "$development_fixture_repo" init -q
git -C "$development_fixture_repo" add \
  harness/scripts/init-project-knowledge.sh \
  harness/scripts/doctor.sh \
  harness/project-templates/MANIFEST.tsv

developer_fixture_script="$development_fixture_harness/scripts/init-project-knowledge.sh"
developer_root_output=$(
  cd "$development_fixture_harness" &&
    bash "$developer_fixture_script" --domain harness --dry-run 2>&1
)
developer_root_exit=$?
if [ "$developer_root_exit" -ne 0 ]; then
  pass "harness development checkout is rejected as implicit target"
else
  fail "harness development checkout is rejected as implicit target"
fi
assert_contains "$developer_root_output" "开发 checkout" "development checkout rejection explains the target"

developer_repo_root_output=$(
  cd "$development_fixture_repo" &&
    bash "$developer_fixture_script" --domain harness --dry-run 2>&1
)
developer_repo_root_exit=$?
if [ "$developer_repo_root_exit" -ne 0 ]; then
  pass "git repository root is rejected as implicit development target"
else
  fail "git repository root is rejected as implicit development target"
fi
assert_contains "$developer_repo_root_output" "开发 checkout" "git repository root rejection explains the target"

installed_fixture_root="$FIXTURE_ROOT/installed-project"
mkdir -p "$installed_fixture_root/scripts/lib" "$installed_fixture_root/docs/superpowers"
cp "$SCRIPT" "$installed_fixture_root/scripts/init-project-knowledge.sh"
cp "$HARNESS_ROOT/scripts/lib/knowledge-manifest.sh" "$installed_fixture_root/scripts/lib/"
cp -R "$HARNESS_ROOT/project-templates" "$installed_fixture_root/"
git -C "$installed_fixture_root" init -q
installed_root_output=$(
  cd "$installed_fixture_root" &&
    bash "$installed_fixture_root/scripts/init-project-knowledge.sh" --domain harness --dry-run 2>&1
)
installed_root_exit=$?
assert_eq "0" "$installed_root_exit" "installed project root is allowed without development markers"
assert_contains "$installed_root_output" "DRY-RUN" "installed project root reports the planned generation"

intermediate_file_root="$FIXTURE_ROOT/intermediate-file"
mkdir -p "$intermediate_file_root"
printf '%s\n' 'not a directory' > "$intermediate_file_root/requirements"
intermediate_file_output=$(run_init "$intermediate_file_root" --domain requirements 2>&1)
intermediate_file_exit=$?
if [ "$intermediate_file_exit" -ne 0 ]; then
  pass "ordinary intermediate parent file is rejected"
else
  fail "ordinary intermediate parent file is rejected"
fi
assert_contains "$intermediate_file_output" "普通文件" "intermediate parent file explains the target type conflict"
assert_no_file "$intermediate_file_root" "PROJECT_MAP.md" "intermediate parent file writes no project map"

case_conflict_root="$FIXTURE_ROOT/case-conflict"
mkdir -p "$case_conflict_root/requirements"
printf '%s\n' 'existing case-conflicting file' > "$case_conflict_root/requirements/map.md"
case_conflict_output=$(run_init "$case_conflict_root" --domain requirements 2>&1)
case_conflict_exit=$?
if [ "$case_conflict_exit" -ne 0 ]; then
  pass "case-conflicting target path is rejected"
else
  fail "case-conflicting target path is rejected"
fi
assert_contains "$case_conflict_output" "大小写" "case-conflicting target explains the collision"
assert_no_file "$case_conflict_root" "PROJECT_MAP.md" "case-conflicting target writes no project map"

readonly_root="$FIXTURE_ROOT/readonly"
mkdir -p "$readonly_root"
chmod 500 "$readonly_root"
readonly_output=$(run_init "$readonly_root" --domain design 2>&1)
readonly_exit=$?
if [ "$readonly_exit" -ne 0 ]; then
  pass "read-only target directory is rejected before generation"
else
  fail "read-only target directory is rejected before generation"
fi
assert_contains "$readonly_output" "写权限" "read-only target explains the permission failure"
chmod 700 "$readonly_root"
assert_no_file "$readonly_root" "PROJECT_MAP.md" "read-only target writes no project map"

plan_tmp_file="$FIXTURE_ROOT/tmpdir-file"
printf '%s\n' 'not a directory' > "$plan_tmp_file"
mkdir -p "$FIXTURE_ROOT/invalid-plan"
plan_output=$(TMPDIR="$plan_tmp_file" run_init "$FIXTURE_ROOT/invalid-plan" --domain design 2>&1)
plan_exit=$?
if [ "$plan_exit" -ne 0 ]; then
  pass "plan file creation failure is reported"
else
  fail "plan file creation failure is reported"
fi
assert_contains "$plan_output" "临时" "plan file failure explains the write boundary"
assert_no_file "$FIXTURE_ROOT/invalid-plan" "PROJECT_MAP.md" "plan file failure writes no project map"

target_root="$FIXTURE_ROOT/target"
mkdir -p "$target_root"

# Preserve an existing user file while allowing the generated domain to add
# its missing navigation entry.
printf '%s\n' '# User root navigation' 'keep this line' > "$target_root/MAP.md"
printf '%s\n' '<!-- init-project-knowledge generated entries -->' '- [legacy-harness](./harness/MAP.md)' >> "$target_root/MAP.md"
mkdir -p "$target_root/harness"
printf '%s\n' '# User harness navigation' 'keep this harness line' > "$target_root/harness/MAP.md"
harness_map_before=$(cat "$target_root/harness/MAP.md")
assert_not_contains "$harness_map_before" "adr.md" "pre-existing harness MAP does not fake generated entries"
run_init "$target_root" --domain harness >/dev/null 2>&1
harness_exit=$?
if [ "$harness_exit" -eq 0 ]; then
  pass "harness domain generates successfully"
else
  fail "harness domain generates successfully"
fi
assert_contains "$(cat "$target_root/MAP.md")" "keep this line" "existing root MAP text is preserved"
assert_file "$target_root" "PROJECT_MAP.md" "project map is generated separately from tool MAP"
assert_contains "$(cat "$target_root/PROJECT_MAP.md")" "项目资料登记" "project map has an independent title"
assert_contains "$(cat "$target_root/PROJECT_MAP.md")" "legacy-harness" "legacy root MAP entries migrate to project map"
assert_contains "$(cat "$target_root/MAP.md")" "legacy-harness" "legacy root MAP remains unchanged"
assert_contains "$(cat "$target_root/harness/MAP.md")" "keep this harness line" "existing domain MAP text is preserved"
assert_contains "$(cat "$target_root/harness/MAP.md")" "adr.md" "custom harness MAP registers generated files"
assert_contains "$(cat "$target_root/harness/MAP.md")" "scenes/MAP.md" "custom harness MAP registers generated submaps"

fresh_harness_root="$FIXTURE_ROOT/fresh-harness"
mkdir -p "$fresh_harness_root"
assert_no_file "$fresh_harness_root" "harness/MAP.md" "fresh harness target starts without a domain MAP"
run_init "$fresh_harness_root" --domain harness >/dev/null 2>&1
fresh_harness_exit=$?
assert_eq "0" "$fresh_harness_exit" "fresh harness domain generation succeeds"
assert_file "$fresh_harness_root" "harness/MAP.md" "fresh harness target creates a domain MAP"
fresh_harness_status=$(sed -nE 's/^status:[[:space:]]*([^[:space:]]+).*$/\1/p' "$fresh_harness_root/harness/MAP.md" | head -1)
assert_eq "draft" "$fresh_harness_status" "fresh harness MAP starts as draft"
assert_contains "$(cat "$fresh_harness_root/harness/MAP.md")" "adr.md" "fresh harness MAP registers generated files"
assert_contains "$(cat "$fresh_harness_root/harness/MAP.md")" "scenes/MAP.md" "fresh harness MAP registers generated scene MAP"
assert_contains "$(cat "$fresh_harness_root/harness/MAP.md")" "diagrams/MAP.md" "fresh harness MAP registers generated diagram MAP"

unsafe_legacy_root="$FIXTURE_ROOT/unsafe-legacy"
mkdir -p "$unsafe_legacy_root"
printf '%s\n' '<!-- init-project-knowledge generated entries -->' '- [escape](../outside.md)' > "$unsafe_legacy_root/MAP.md"
unsafe_legacy_output=$(run_init "$unsafe_legacy_root" --domain harness 2>&1)
unsafe_legacy_exit=$?
if [ "$unsafe_legacy_exit" -ne 0 ]; then
  pass "unsafe legacy MAP link is rejected before generation"
else
  fail "unsafe legacy MAP link is rejected before generation"
fi
assert_contains "$unsafe_legacy_output" "旧 MAP 迁移候选" "unsafe legacy MAP explains the migration boundary"
assert_no_file "$unsafe_legacy_root" "PROJECT_MAP.md" "unsafe legacy MAP writes no project map"

for simple_domain in design docs; do
  simple_root="$FIXTURE_ROOT/$simple_domain"
  mkdir -p "$simple_root"
  run_init "$simple_root" --domain "$simple_domain" >/dev/null 2>&1
  simple_exit=$?
  if [ "$simple_exit" -eq 0 ]; then
    pass "$simple_domain domain generates successfully"
  else
    fail "$simple_domain domain generates successfully"
  fi
  assert_file "$simple_root" "$simple_domain/MAP.md" "$simple_domain MAP is generated"
done

requirements_root="$FIXTURE_ROOT/requirements"
mkdir -p "$requirements_root"
run_init "$requirements_root" --domain requirements --module orders >/dev/null 2>&1
requirements_exit=$?
if [ "$requirements_exit" -eq 0 ]; then
  pass "requirements domain with module generates successfully"
else
  fail "requirements domain with module generates successfully"
fi
assert_file "$requirements_root" "requirements/modules/orders.md" "module template is instantiated"
assert_no_file "$requirements_root" "requirements/modules/_module.md" "module source is never emitted as a business record"
module_text=$(cat "$requirements_root/requirements/modules/orders.md" 2>/dev/null || true)
assert_contains "$module_text" "orders" "module placeholder is rendered"
assert_not_contains "$module_text" "{{MODULE}}" "module placeholder is fully rendered"
assert_contains "$(cat "$requirements_root/requirements/modules/MAP.md" 2>/dev/null || true)" "orders.md" "module MAP registers the module"

experience_root="$FIXTURE_ROOT/experience"
mkdir -p "$experience_root"
run_init "$experience_root" --domain experience --case keyboard-focus >/dev/null 2>&1
experience_exit=$?
if [ "$experience_exit" -eq 0 ]; then
  pass "experience domain with case generates successfully"
else
  fail "experience domain with case generates successfully"
fi
assert_file "$experience_root" "badcase/keyboard-focus.md" "case template is instantiated"
assert_no_file "$experience_root" "badcase/_case.md" "case source is never emitted as a business record"
case_text=$(cat "$experience_root/badcase/keyboard-focus.md" 2>/dev/null || true)
assert_contains "$case_text" "keyboard-focus" "case placeholder is rendered"
assert_not_contains "$case_text" "{{CASE}}" "case placeholder is fully rendered"
assert_contains "$(cat "$experience_root/badcase/MAP.md" 2>/dev/null || true)" "keyboard-focus.md" "case MAP registers the case"
if printf '%s\n' "$case_text" | grep -qE '需求/模块 ID.* /[[:space:]]*$'; then
  fail "case template does not erase an absent module identifier"
else
  pass "case template does not erase an absent module identifier"
fi

experience_plain_root="$FIXTURE_ROOT/experience-plain"
mkdir -p "$experience_plain_root"
run_init "$experience_plain_root" --domain experience >/dev/null 2>&1
plain_experience_text=$(cat "$experience_plain_root/experience/aibrain/preflight.md" 2>/dev/null || true)
assert_contains "$(cat "$experience_plain_root/PROJECT_MAP.md" 2>/dev/null || true)" "./badcase/MAP.md" "experience root MAP registers badcase MAP"
assert_not_contains "$plain_experience_text" "owner: ../" "experience owner is not rendered as a relative path"
if printf '%s\n' "$plain_experience_text" | grep -qE '需求/模块 ID.* /[[:space:]]*$'; then
  fail "experience-only template does not erase an absent module identifier"
else
  pass "experience-only template does not erase an absent module identifier"
fi

# Every static manifest row is generated by all, and template status is
# downgraded only in generated copies.
all_root="$FIXTURE_ROOT/all"
mkdir -p "$all_root"
template_checksum_before=$(cksum "$HARNESS_ROOT/project-templates/harness/MAP.md")
root_map_checksum_before=$(cksum "$HARNESS_ROOT/MAP.md")
run_init "$all_root" --domain all >/dev/null 2>&1
all_exit=$?
if [ "$all_exit" -eq 0 ]; then
  pass "all domains generate successfully"
else
  fail "all domains generate successfully"
fi
template_checksum_after=$(cksum "$HARNESS_ROOT/project-templates/harness/MAP.md")
assert_eq "$template_checksum_before" "$template_checksum_after" "generation does not modify source templates"
root_map_checksum_after=$(cksum "$HARNESS_ROOT/MAP.md")
assert_eq "$root_map_checksum_before" "$root_map_checksum_after" "generation does not modify the distributed root MAP"
check_local_links "$all_root" "$all_root/PROJECT_MAP.md" "generated project MAP"
assert_contains "$(cat "$all_root/PROJECT_MAP.md")" "./badcase/MAP.md" "all project MAP registers badcase MAP"
all_badcase_root_count=$(grep -F -c '](./badcase/MAP.md)' "$all_root/PROJECT_MAP.md" 2>/dev/null || true)
assert_eq "1" "$all_badcase_root_count" "all root MAP registers badcase once"
while IFS= read -r generated_file; do
  check_local_links "$all_root" "$generated_file" "generated $(basename "$generated_file")"
done < <(find "$all_root" -type f -name '*.md' -print | sort)
while IFS=$'\t' read -r domain relative_path kind; do
  case "$relative_path" in
    ''|\#*) continue ;;
  esac
  [ "$kind" = "static" ] || continue
  assert_file "$all_root" "$relative_path" "all generates $relative_path"
  generated_status=$(sed -nE 's/^(status:[[:space:]]*[^[:space:]]+).*$/\1/p' "$all_root/$relative_path" | head -1)
  assert_eq "status: draft" "$generated_status" "$relative_path is emitted with exact draft status"
done < "$HARNESS_ROOT/project-templates/MANIFEST.tsv"

# Re-running is idempotent: no duplicate dynamic index entries and no target
# replacement.  The root MAP keeps the first generated registration only.
module_before=$(cat "$requirements_root/requirements/modules/orders.md")
run_init "$requirements_root" --domain requirements --module orders >/dev/null 2>&1
assert_eq "0" "$?" "repeated module generation succeeds"
module_after=$(cat "$requirements_root/requirements/modules/orders.md")
assert_eq "$module_before" "$module_after" "repeated generation preserves existing module"
orders_count=$(grep -F -c 'orders.md' "$requirements_root/requirements/modules/MAP.md" 2>/dev/null || true)
assert_eq "1" "$orders_count" "repeated generation does not duplicate module index"

# A symlinked target component is rejected before any output is written.
symlink_root="$FIXTURE_ROOT/symlink"
outside_root="$FIXTURE_ROOT/outside"
mkdir -p "$symlink_root" "$outside_root"
ln -s "$outside_root" "$symlink_root/requirements"
symlink_output=$(run_init "$symlink_root" --domain requirements 2>&1)
symlink_exit=$?
if [ "$symlink_exit" -ne 0 ]; then
  pass "target symlink escape is rejected"
else
  fail "target symlink escape is rejected"
fi
assert_contains "$symlink_output" "符号链接" "symlink rejection explains the boundary"
assert_eq "0" "$(find "$outside_root" -type f -print | wc -l | tr -d ' ')" "target symlink rejection writes no outside files"

prepare_manifest_distribution() {
  local distribution_root="$1"
  local target_root="$2"
  mkdir -p "$distribution_root/scripts/lib" "$target_root"
  cp "$SCRIPT" "$distribution_root/scripts/init-project-knowledge.sh"
  cp "$HARNESS_ROOT/scripts/lib/knowledge-manifest.sh" "$distribution_root/scripts/lib/"
  cp -R "$HARNESS_ROOT/project-templates" "$distribution_root/"
}

duplicate_manifest_distribution="$FIXTURE_ROOT/duplicate-manifest-distribution"
duplicate_manifest_target="$FIXTURE_ROOT/duplicate-manifest-target"
prepare_manifest_distribution "$duplicate_manifest_distribution" "$duplicate_manifest_target"
sed -n '1p' "$duplicate_manifest_distribution/project-templates/MANIFEST.tsv" >> "$duplicate_manifest_distribution/project-templates/MANIFEST.tsv"
duplicate_manifest_output=$(
  cd "$duplicate_manifest_target" &&
    bash "$duplicate_manifest_distribution/scripts/init-project-knowledge.sh" --domain harness 2>&1
)
duplicate_manifest_exit=$?
if [ "$duplicate_manifest_exit" -ne 0 ]; then
  pass "duplicate manifest path is rejected"
else
  fail "duplicate manifest path is rejected"
fi
assert_contains "$duplicate_manifest_output" "重复" "duplicate manifest explains the conflict"
assert_no_file "$duplicate_manifest_target" "PROJECT_MAP.md" "duplicate manifest writes no project map"

crlf_manifest_distribution="$FIXTURE_ROOT/crlf-manifest-distribution"
crlf_manifest_target="$FIXTURE_ROOT/crlf-manifest-target"
prepare_manifest_distribution "$crlf_manifest_distribution" "$crlf_manifest_target"
awk '{ printf "%s\r\n", $0 }' "$crlf_manifest_distribution/project-templates/MANIFEST.tsv" > "$crlf_manifest_distribution/project-templates/MANIFEST.crlf"
mv "$crlf_manifest_distribution/project-templates/MANIFEST.crlf" "$crlf_manifest_distribution/project-templates/MANIFEST.tsv"
crlf_manifest_output=$(
  cd "$crlf_manifest_target" &&
    bash "$crlf_manifest_distribution/scripts/init-project-knowledge.sh" --domain harness 2>&1
)
crlf_manifest_exit=$?
if [ "$crlf_manifest_exit" -ne 0 ]; then
  pass "CRLF manifest is rejected consistently"
else
  fail "CRLF manifest is rejected consistently"
fi
assert_contains "$crlf_manifest_output" "CR/CRLF" "CRLF manifest explains the line-ending contract"
assert_no_file "$crlf_manifest_target" "PROJECT_MAP.md" "CRLF manifest writes no project map"

bom_manifest_distribution="$FIXTURE_ROOT/bom-manifest-distribution"
bom_manifest_target="$FIXTURE_ROOT/bom-manifest-target"
prepare_manifest_distribution "$bom_manifest_distribution" "$bom_manifest_target"
{ printf '\357\273\277'; cat "$bom_manifest_distribution/project-templates/MANIFEST.tsv"; } > "$bom_manifest_distribution/project-templates/MANIFEST.bom"
mv "$bom_manifest_distribution/project-templates/MANIFEST.bom" "$bom_manifest_distribution/project-templates/MANIFEST.tsv"
bom_manifest_output=$(
  cd "$bom_manifest_target" &&
    bash "$bom_manifest_distribution/scripts/init-project-knowledge.sh" --domain harness 2>&1
)
bom_manifest_exit=$?
if [ "$bom_manifest_exit" -ne 0 ]; then
  pass "BOM manifest is rejected consistently"
else
  fail "BOM manifest is rejected consistently"
fi
assert_contains "$bom_manifest_output" "BOM" "BOM manifest explains the encoding contract"
assert_no_file "$bom_manifest_target" "PROJECT_MAP.md" "BOM manifest writes no project map"

cross_domain_manifest_distribution="$FIXTURE_ROOT/cross-domain-manifest-distribution"
cross_domain_manifest_target="$FIXTURE_ROOT/cross-domain-manifest-target"
prepare_manifest_distribution "$cross_domain_manifest_distribution" "$cross_domain_manifest_target"
printf '%s\n' 'harness	badcase/MAP.md	static' >> "$cross_domain_manifest_distribution/project-templates/MANIFEST.tsv"
cross_domain_manifest_output=$(
  cd "$cross_domain_manifest_target" &&
    bash "$cross_domain_manifest_distribution/scripts/init-project-knowledge.sh" --domain harness 2>&1
)
cross_domain_manifest_exit=$?
if [ "$cross_domain_manifest_exit" -ne 0 ]; then
  pass "cross-domain manifest path is rejected"
else
  fail "cross-domain manifest path is rejected"
fi
assert_contains "$cross_domain_manifest_output" "domain 与 path" "cross-domain manifest explains the path boundary"
assert_no_file "$cross_domain_manifest_target" "PROJECT_MAP.md" "cross-domain manifest writes no project map"

broken_distribution="$FIXTURE_ROOT/broken-distribution"
broken_target="$FIXTURE_ROOT/broken-target"
mkdir -p "$broken_distribution/scripts/lib" "$broken_target"
cp "$SCRIPT" "$broken_distribution/scripts/init-project-knowledge.sh"
cp "$HARNESS_ROOT/scripts/lib/knowledge-manifest.sh" "$broken_distribution/scripts/lib/"
cp -R "$HARNESS_ROOT/project-templates" "$broken_distribution/"
rm "$broken_distribution/project-templates/MANIFEST.tsv"
broken_output=$(
  cd "$broken_target" &&
    bash "$broken_distribution/scripts/init-project-knowledge.sh" --domain harness 2>&1
)
broken_exit=$?
if [ "$broken_exit" -ne 0 ]; then
  pass "broken template distribution fails explicitly"
else
  fail "broken template distribution fails explicitly"
fi
assert_contains "$broken_output" "模板清单" "broken distribution explains the missing manifest"
assert_no_file "$broken_target" "MAP.md" "broken distribution does not write a root MAP"

missing_source_distribution="$FIXTURE_ROOT/missing-source-distribution"
missing_source_target="$FIXTURE_ROOT/missing-source-target"
mkdir -p "$missing_source_distribution/scripts/lib" "$missing_source_target"
cp "$SCRIPT" "$missing_source_distribution/scripts/init-project-knowledge.sh"
cp "$HARNESS_ROOT/scripts/lib/knowledge-manifest.sh" "$missing_source_distribution/scripts/lib/"
cp -R "$HARNESS_ROOT/project-templates" "$missing_source_distribution/"
rm "$missing_source_distribution/project-templates/harness/adr.md"
missing_source_output=$(
  cd "$missing_source_target" &&
    bash "$missing_source_distribution/scripts/init-project-knowledge.sh" --domain harness 2>&1
)
missing_source_exit=$?
if [ "$missing_source_exit" -ne 0 ]; then
  pass "selected missing source fails before generation"
else
  fail "selected missing source fails before generation"
fi
assert_contains "$missing_source_output" "找不到模板源文件" "missing source explains the source failure"
assert_no_file "$missing_source_target" "MAP.md" "missing source writes no root MAP"
assert_no_file "$missing_source_target" "harness/adr.md" "missing source writes no partial domain files"

source_symlink_distribution="$FIXTURE_ROOT/source-symlink-distribution"
source_symlink_target="$FIXTURE_ROOT/source-symlink-target"
source_symlink_outside="$FIXTURE_ROOT/source-symlink-outside"
mkdir -p "$source_symlink_distribution/scripts/lib" "$source_symlink_target" "$source_symlink_outside"
cp "$SCRIPT" "$source_symlink_distribution/scripts/init-project-knowledge.sh"
cp "$HARNESS_ROOT/scripts/lib/knowledge-manifest.sh" "$source_symlink_distribution/scripts/lib/"
cp -R "$HARNESS_ROOT/project-templates" "$source_symlink_distribution/"
printf '%s\n' '# outside source' > "$source_symlink_outside/adr.md"
rm "$source_symlink_distribution/project-templates/harness/adr.md"
ln -s "$source_symlink_outside/adr.md" "$source_symlink_distribution/project-templates/harness/adr.md"
source_symlink_output=$(
  cd "$source_symlink_target" &&
    bash "$source_symlink_distribution/scripts/init-project-knowledge.sh" --domain harness 2>&1
)
source_symlink_exit=$?
if [ "$source_symlink_exit" -ne 0 ]; then
  pass "source template symlink is rejected"
else
  fail "source template symlink is rejected"
fi
assert_contains "$source_symlink_output" "模板源路径不允许符号链接" "source symlink explains the source boundary"
assert_no_file "$source_symlink_target" "MAP.md" "source symlink writes no root MAP"

module_map_collision_root="$FIXTURE_ROOT/module-map-collision"
mkdir -p "$module_map_collision_root"
module_map_collision_output=$(run_init "$module_map_collision_root" --domain requirements --module MAP 2>&1)
module_map_collision_exit=$?
if [ "$module_map_collision_exit" -ne 0 ]; then
  pass "module MAP target collision is rejected"
else
  fail "module MAP target collision is rejected"
fi
assert_contains "$module_map_collision_output" "MAP" "module MAP collision explains the target conflict"
assert_no_file "$module_map_collision_root" "MAP.md" "module MAP collision writes no root MAP"

case_map_collision_root="$FIXTURE_ROOT/case-map-collision"
mkdir -p "$case_map_collision_root"
case_map_collision_output=$(run_init "$case_map_collision_root" --domain experience --case MAP 2>&1)
case_map_collision_exit=$?
if [ "$case_map_collision_exit" -ne 0 ]; then
  pass "case MAP target collision is rejected"
else
  fail "case MAP target collision is rejected"
fi
assert_contains "$case_map_collision_output" "MAP" "case MAP collision explains the target conflict"
assert_no_file "$case_map_collision_root" "MAP.md" "case MAP collision writes no root MAP"

# The optional knowledge package coexists with both supported frontend
# initialization flavors.  It lives outside docs/specs and therefore must not
# change the specs gate (or require a package manager/framework).
for flavor in pc mini; do
  frontend_root="$FIXTURE_ROOT/frontend-$flavor"
  mkdir -p "$frontend_root"
  cp -R "$HARNESS_ROOT/spec-templates" "$frontend_root/"
  cp -R "$HARNESS_ROOT/project-templates" "$frontend_root/"
  cp -R "$HARNESS_ROOT/scripts" "$frontend_root/"
  if [ "$flavor" = "pc" ]; then
    cp -R "$HARNESS_ROOT/token-templates" "$frontend_root/"
  fi
  (
    cd "$frontend_root" &&
      bash scripts/init-specs.sh --flavor "$flavor" >/dev/null &&
      bash scripts/init-project-knowledge.sh --domain requirements --module "$flavor-fixture" >/dev/null
  )
  fixture_state=$(
    . "$frontend_root/scripts/lib/specs-state.sh"
    specs_state "$frontend_root"
  )
  assert_eq "draft" "$fixture_state" "$flavor knowledge generation keeps specs draft"
  assert_file "$frontend_root" "requirements/modules/$flavor-fixture.md" "$flavor knowledge module is generated outside specs"
  assert_no_file "$frontend_root" "docs/specs/requirements/MAP.md" "$flavor knowledge does not enter frontend specs"
done

active_frontend_root="$FIXTURE_ROOT/frontend-active"
mkdir -p "$active_frontend_root/docs/specs" "$active_frontend_root/bin"
cp -R "$HARNESS_ROOT/project-templates" "$active_frontend_root/"
cp -R "$HARNESS_ROOT/scripts" "$active_frontend_root/"
cp "$HARNESS_ROOT/MAP.md" "$active_frontend_root/MAP.md"
cp "$HARNESS_ROOT/VERSION" "$active_frontend_root/VERSION"
git -C "$active_frontend_root" init -q
printf '%s\n' '{"name":"active-knowledge-fixture","scripts":{}}' > "$active_frontend_root/package.json"
printf '%s\n' '{}' > "$active_frontend_root/tsconfig.json"
printf '%s\n' '---' 'status: active' '---' 'project: active fixture' > "$active_frontend_root/docs/specs/00_PROJECT_FACTS.md"
printf '%s\n' '# Index' > "$active_frontend_root/docs/specs/INDEX.md"
printf '%s\n' '# dangerous zones' > "$active_frontend_root/docs/specs/dangerous-zones.txt"
printf '%s\n' '#!/bin/sh' 'exit 0' > "$active_frontend_root/bin/node"
printf '%s\n' '#!/bin/sh' 'exit 0' > "$active_frontend_root/bin/pnpm"
chmod +x "$active_frontend_root/bin/node" "$active_frontend_root/bin/pnpm"
(
  cd "$active_frontend_root" &&
    bash scripts/init-project-knowledge.sh --domain requirements --module active-fixture >/dev/null &&
    PATH="$active_frontend_root/bin:$PATH" bash scripts/doctor.sh --project --strict >/dev/null 2>&1
)
active_doctor_exit=$?
if [ "$active_doctor_exit" -eq 0 ]; then
  pass "active frontend fixture knowledge generation passes doctor strict"
else
  fail "active frontend fixture knowledge generation passes doctor strict"
fi
assert_eq "active" "$({ . "$active_frontend_root/scripts/lib/specs-state.sh"; specs_state "$active_frontend_root"; })" "active fixture remains active after knowledge generation"

finish_tests
