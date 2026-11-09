#!/bin/bash
set -u

TEST_DIR=$(cd "$(dirname "$0")" && pwd -P)
HARNESS_ROOT=$(cd "$TEST_DIR/../.." && pwd -P)
. "$TEST_DIR/testlib.sh"

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

# Contract scope: local Markdown path targets are resolved from the file that
# owns the link. Fragment targets are required to name a non-empty fragment;
# renderer-specific slug rules are outside this shell contract.
check_local_links() {
  local root="$1"
  local file_path="$2"
  local label_prefix="$3"
  local base_dir
  local link
  local relative_target
  local target_path
  local fragment
  base_dir=$(cd "$(dirname "$file_path")" && pwd -P)
  while IFS= read -r link; do
    relative_target="${link#](}"
    relative_target="${relative_target%)}"
    case "$relative_target" in
      ''|'#'*|'http://'*|'https://'*|'mailto:'*) continue ;;
    esac
    target_path="${relative_target%%#*}"
    fragment=""
    case "$relative_target" in
      *'#'*) fragment="${relative_target#*#}" ;;
    esac
    if [ -n "$fragment" ] && [ -z "$target_path" ]; then
      fail "$label_prefix fragment names a file"
      continue
    fi
    if [ -z "$target_path" ]; then
      target_path="$(basename "$file_path")"
    fi
    if [ -e "$base_dir/$target_path" ]; then
      if [ -n "$fragment" ]; then
        pass "$label_prefix fragment is explicit: #$fragment"
      fi
    else
      fail "$label_prefix local link resolves: $target_path"
    fi
  done < <(grep -oE '\]\([^)]*\)' "$file_path" 2>/dev/null || true)
}

assert_file "$HARNESS_ROOT" "MAP.md" "root MAP exists"
assert_file "$HARNESS_ROOT" "docs/harness/knowledge.md" "harness knowledge contract exists"
assert_file "$HARNESS_ROOT" "docs/harness/verification.md" "harness verification contract exists"
check_local_links "$HARNESS_ROOT" "$HARNESS_ROOT/MAP.md" "MAP"
check_local_links "$HARNESS_ROOT" "$HARNESS_ROOT/docs/harness/knowledge.md" "knowledge"
check_local_links "$HARNESS_ROOT" "$HARNESS_ROOT/docs/harness/verification.md" "verification"

map_text=$(cat "$HARNESS_ROOT/MAP.md")
assert_contains "$map_text" "Harness 本体" "MAP separates distributed harness materials"
assert_contains "$map_text" "接入项目后的前端领域入口" "MAP routes project specs only after initialization"
assert_contains "$map_text" "按需业务资料" "MAP routes optional business materials"
assert_contains "$map_text" "全系统/跨端架构" "MAP routes system architecture separately"
assert_contains "$map_text" "前端领域架构" "MAP routes frontend architecture separately"
assert_contains "$map_text" "draft" "MAP routes draft specs"
assert_contains "$map_text" "draft 继续填充" "MAP tells draft specs to continue filling"
assert_not_contains "$map_text" "系统架构和 ADR 在哪里？ | 项目 \`docs/specs/02_ARCHITECTURE.md\`" "MAP does not collapse system architecture into frontend specs"
assert_not_contains "$map_text" "](./docs/specs/" "MAP does not make absent project specs look present"

knowledge_text=$(cat "$HARNESS_ROOT/docs/harness/knowledge.md")
assert_contains "$knowledge_text" "目标、当前实现、团队规范、决策和环境证据" "knowledge contract defines the five knowledge types"
assert_contains "$knowledge_text" "用户确认状态" "knowledge contract separates user confirmation state"
assert_contains "$knowledge_text" "实现状态" "knowledge contract separates implementation state"
assert_contains "$knowledge_text" "验收结果" "knowledge contract separates verification result"
knowledge_allowed=$(sed -n 's/^| 实现（Implementation）.*| \(.*\) |$/\1/p' "$HARNESS_ROOT/docs/harness/knowledge.md")
knowledge_format=$(sed -n 's/^实现状态: \(.*\)$/\1/p' "$HARNESS_ROOT/docs/harness/knowledge.md")
for implementation_state in not-started partial observed not-found; do
  assert_contains "$knowledge_allowed" "$implementation_state" "knowledge table allows implementation state $implementation_state"
  assert_contains "$knowledge_format" "$implementation_state" "knowledge record format allows implementation state $implementation_state"
done
assert_not_contains "$knowledge_allowed" "implemented" "knowledge table does not introduce a divergent implementation enum"

verification_text=$(cat "$HARNESS_ROOT/docs/harness/verification.md")
assert_contains "$verification_text" "独立 QA" "verification contract defines independent QA"
assert_contains "$verification_text" "原实现者之外的角色" "verification requires an independent role"
assert_contains "$verification_text" "自检不能算独立 QA" "verification excludes implementer self-check from independent QA"
assert_contains "$verification_text" "新增功能、业务规则变化" "verification names feature and business-rule triggers"
assert_contains "$verification_text" "同一问题连续两轮" "verification contract defines the two-round escalation boundary"
assert_contains "$verification_text" "blocked" "verification contract preserves blocked evidence"
assert_contains "$verification_text" "需要独立 QA，当前受阻" "verification contract does not downgrade blocked QA"
assert_contains "$verification_text" "业务验收" "verification contract separates business acceptance"

for entry_file in AGENTS.md CLAUDE.md .cursor/rules/project-harness.mdc .windsurfrules; do
  entry_text=$(cat "$HARNESS_ROOT/$entry_file")
  assert_contains "$entry_text" "MAP.md" "$entry_file routes through the root MAP"
  assert_contains "$entry_text" "docs/harness/verification.md" "$entry_file routes the shared verification contract"
done

schema_text=$(cat "$HARNESS_ROOT/spec-templates/SCHEMA.md")
assert_contains "$schema_text" "docs/harness/knowledge.md" "schema routes shared knowledge instead of copying it"
assert_contains "$schema_text" "status: active" "schema keeps implementation review distinct from acceptance"
for flavor in pc-microapp miniprogram-uniapp; do
  flavor_root="$HARNESS_ROOT/spec-templates/$flavor"
  index_file="$flavor_root/INDEX.md"
  rule_file="$flavor_root/RULE.md"
  domain_file="$flavor_root/03_BUSINESS_DOMAIN.md"
  playbook_file="$flavor_root/08_TASK_PLAYBOOKS.md"
  check_local_links "$HARNESS_ROOT" "$index_file" "$flavor INDEX"
  check_local_links "$HARNESS_ROOT" "$rule_file" "$flavor RULE"
  check_local_links "$HARNESS_ROOT" "$domain_file" "$flavor business"
  check_local_links "$HARNESS_ROOT" "$playbook_file" "$flavor playbooks"
  assert_contains "$(cat "$index_file")" "docs/harness/verification.md" "$flavor INDEX routes shared verification"
  assert_contains "$(cat "$rule_file")" "实现事实" "$flavor RULE names implementation facts"
  assert_contains "$(cat "$domain_file")" "目标与实现事实" "$flavor business template separates target and implementation"
  assert_contains "$(cat "$playbook_file")" "独立 QA" "$flavor playbooks defer QA to the shared contract"
done

for command_file in .claude/commands/*.md; do
  assert_contains "$(cat "$HARNESS_ROOT/$command_file")" "docs/harness/verification.md" "$(basename "$command_file") uses the shared verification contract"
done
init_text=$(cat "$HARNESS_ROOT/.claude/commands/init-specs.md")
assert_contains "$init_text" "实现事实" "initializer records implementation facts only"
assert_contains "$init_text" "两轮" "initializer follows the shared escalation boundary"
assert_contains "$init_text" "missing" "initializer runs the scaffold only for missing specs"
assert_contains "$init_text" "draft" "initializer routes draft specs to continued filling"
assert_contains "$init_text" "active" "initializer skips active specs"
assert_contains "$init_text" "13_AGENT_POLICY" "initializer includes the agent policy document"
assert_not_contains "$init_text" '已存在` → 视为已初始化' "initializer does not collapse draft and active states"

readme_text=$(cat "$HARNESS_ROOT/README.md")
assert_contains "$readme_text" "MAP.md" "README documents the root MAP"
assert_contains "$readme_text" "docs/harness/" "README documents shared harness contracts"
assert_contains "$readme_text" "Harness 2.0 开发版（基于 v2.9）" "README names the development version factually"
assert_contains "$readme_text" "脚本不覆盖并退出" "README distinguishes draft script behavior"
assert_contains "$readme_text" "Claude \`/init-specs\` 继续填充" "README distinguishes Claude draft behavior"
assert_not_contains "$readme_text" "伪装" "README avoids conversational version wording"
changelog_text=$(cat "$HARNESS_ROOT/CHANGELOG.md")
assert_contains "$changelog_text" "Harness 2.0 开发版（基于 v2.9）" "CHANGELOG records the development version factually"
assert_not_contains "$changelog_text" "用户面向" "CHANGELOG avoids conversational version wording"
assert_not_contains "$changelog_text" "伪装" "CHANGELOG avoids conversational version wording"

# The self doctor must treat the distributed navigation and shared contracts as required.
FIXTURE_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/harness-2-navigation.XXXXXX")
trap 'rm -rf "$FIXTURE_ROOT"' EXIT
doctor_root="$FIXTURE_ROOT/doctor-missing"
mkdir -p "$doctor_root"
cp -R "$HARNESS_ROOT/." "$doctor_root/"
rm -f "$doctor_root/MAP.md" "$doctor_root/docs/harness/knowledge.md" "$doctor_root/docs/harness/verification.md"
(
  cd "$doctor_root" &&
    bash scripts/doctor.sh --self --strict
) >/dev/null 2>&1
doctor_exit=$?
if [ "$doctor_exit" -ne 0 ]; then
  pass "self doctor rejects a distribution missing navigation contracts"
else
  fail "self doctor rejects a distribution missing navigation contracts"
fi

# A draft outside docs/specs must not change the specs state or get copied into it.
for flavor in pc mini; do
  project_root="$FIXTURE_ROOT/$flavor"
  mkdir -p "$project_root/docs/requirements"
  cp -R "$HARNESS_ROOT/spec-templates" "$project_root/"
  cp -R "$HARNESS_ROOT/project-templates" "$project_root/"
  cp -R "$HARNESS_ROOT/scripts" "$project_root/"
  cp -R "$HARNESS_ROOT/.claude" "$project_root/"
  cp -R "$HARNESS_ROOT/.codex" "$project_root/"
  cp -R "$HARNESS_ROOT/.cursor" "$project_root/"
  cp "$HARNESS_ROOT/.windsurfrules" "$project_root/.windsurfrules"
  cp "$HARNESS_ROOT/AGENTS.md" "$project_root/AGENTS.md"
  cp "$HARNESS_ROOT/CLAUDE.md" "$project_root/CLAUDE.md"
  cp "$HARNESS_ROOT/MAP.md" "$project_root/MAP.md"
  mkdir -p "$project_root/docs/harness"
  cp -R "$HARNESS_ROOT/docs/harness/." "$project_root/docs/harness/"
  printf '%s\n' '---' 'status: draft' '---' 'goal: external requirement' > "$project_root/docs/requirements/new-feature.md"
  (
    cd "$project_root" &&
      bash scripts/init-specs.sh --flavor "$flavor"
  ) >/dev/null
  initialized_state=$(
    . "$project_root/scripts/lib/specs-state.sh"
    specs_state "$project_root"
  )
  assert_eq "draft" "$initialized_state" "$flavor initializer keeps template specs draft"
  check_local_links "$project_root" "$project_root/MAP.md" "$flavor copied MAP"
  check_local_links "$project_root" "$project_root/docs/specs/INDEX.md" "$flavor generated INDEX"
  assert_not_contains "$(find "$project_root/docs/specs" -type f -print)" "new-feature.md" "$flavor initializer excludes external requirements"

  active_root="$FIXTURE_ROOT/$flavor-active"
  mkdir -p "$active_root/docs/specs" "$active_root/docs/requirements"
  printf '%s\n' '---' 'status: active' '---' 'project: fixture' > "$active_root/docs/specs/00_PROJECT_FACTS.md"
  printf '%s\n' '---' 'status: draft' '---' 'goal: external requirement' > "$active_root/docs/requirements/new-feature.md"
  active_state=$(
    . "$project_root/scripts/lib/specs-state.sh"
    specs_state "$active_root"
  )
  assert_eq "active" "$active_state" "$flavor external draft does not pollute specs state"
done

finish_tests
