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

agents=$(sed -n '1,180p' "$HARNESS_ROOT/AGENTS.md")
assert_contains "$agents" "Figma 链接或截图" "cross-agent guidance routes design inputs"
assert_contains "$agents" "列表 / 新建编辑 / 详情" "cross-agent guidance classifies page archetypes"
assert_contains "$agents" "视觉验收" "cross-agent guidance requires visual acceptance"

new_page=$(sed -n '1,220p' "$HARNESS_ROOT/.claude/commands/new-page.md")
assert_contains "$new_page" "拆分预判" "new-page preserves the v2.9 component split preflight"
assert_contains "$new_page" "Figma 链接或截图" "new-page routes design inputs before implementation"
assert_contains "$new_page" "列表、新建/编辑或详情" "new-page classifies the target page archetype"
assert_contains "$new_page" "视觉验收" "new-page requires visual acceptance evidence"

tech_solution=$(sed -n '1,220p' "$HARNESS_ROOT/.claude/commands/tech-solution.md")
assert_contains "$tech_solution" "Figma / 截图证据" "tech-solution records design evidence"
assert_contains "$tech_solution" "页面类型与组件映射" "tech-solution maps archetypes to verified components"
assert_contains "$tech_solution" "视觉验收点" "tech-solution defines visual acceptance"

ui_guide=$(sed -n '1,220p' "$HARNESS_ROOT/spec-templates/pc-microapp/06_UI_COMPONENT_GUIDE.md")
assert_contains "$ui_guide" "页面类型与设计输入" "pc UI template routes Figma and screenshot context"
assert_contains "$ui_guide" "项目声明的最小宽度" "pc UI template avoids hard-coded project minimum widths"
assert_contains "$ui_guide" "PC 画布与自适应" "pc UI template preserves viewport guidance"

component_index=$(sed -n '1,180p' "$HARNESS_ROOT/spec-templates/pc-microapp/dcgj-components/COMPONENT_INDEX.md")
assert_contains "$component_index" "实际锁定版本" "component index records the installed library version"
assert_contains "$component_index" "导出入口" "component index verifies component exports"
assert_contains "$component_index" "真实调用位置" "component index records real project usage"

examples=$(sed -n '1,180p' "$HARNESS_ROOT/spec-templates/pc-microapp/examples/README.md")
assert_contains "$examples" "EXAMPLE_<DOMAIN>_OVERVIEW.md" "examples route readers through an overview"
assert_contains "$examples" "EXAMPLE_<DOMAIN>_LIST_PC.md" "examples define a list-page reference"
assert_contains "$examples" "EXAMPLE_<DOMAIN>_FORM_PC.md" "examples define a form-page reference"
assert_contains "$examples" "EXAMPLE_<DOMAIN>_DETAIL_PC.md" "examples define a detail-page reference"

pc_rule=$(sed -n '1,180p' "$HARNESS_ROOT/spec-templates/pc-microapp/RULE.md")
assert_contains "$pc_rule" "组件库导出入口" "pc initialization inspects component exports"
assert_contains "$pc_rule" "真实调用" "pc initialization derives patterns from call sites"

changelog=$(sed -n '1,100p' "$HARNESS_ROOT/CHANGELOG.md")
assert_contains "$changelog" "Figma / 截图上下文路由" "changelog explains the new design-input mechanism"

minimal_agents=$(sed -n '1,140p' "$HARNESS_ROOT/AGENTS.md")
assert_contains "$minimal_agents" "**active**" "minimal AGENTS context defines the active specs state"
assert_contains "$minimal_agents" "**draft**" "minimal AGENTS context defines the draft specs state"
assert_contains "$minimal_agents" "**missing**" "minimal AGENTS context defines the missing specs state"
assert_contains "$minimal_agents" "docs/specs/00_PROJECT_FACTS.md" "minimal AGENTS context loads project facts"
assert_contains "$minimal_agents" "docs/specs/11_DANGEROUS_AREAS.md" "minimal AGENTS context loads dangerous areas"
assert_contains "$minimal_agents" "docs/specs/13_AGENT_POLICY.md" "minimal AGENTS context routes authorization policy"
assert_contains "$minimal_agents" "run-verification-profile.sh" "minimal AGENTS context routes verification"
assert_contains "$minimal_agents" ".claude/commands/<name>.md" "minimal AGENTS context routes commands"
assert_contains "$minimal_agents" "优先复用已有模式" "minimal AGENTS context preserves reuse boundary"
assert_contains "$minimal_agents" "不得编造字段、API、目录、框架或 UI" "minimal AGENTS context preserves no-invention boundary"
assert_contains "$minimal_agents" "不改公共基础设施、认证/请求封装、全局配置或无关代码" "minimal AGENTS context preserves infrastructure boundary"
assert_contains "$minimal_agents" "完成前验证" "minimal AGENTS context preserves verification boundary"
assert_not_contains "$minimal_agents" '基座 `apps/micro-main` + 子应用' "minimal AGENTS context omits retired architecture guidance"
assert_not_contains "$minimal_agents" "Vue3 + micro-app + dcgj-ui" "minimal AGENTS context omits PC implementation details"
assert_not_contains "$minimal_agents" "uni-app + Vue3 + uview-plus" "minimal AGENTS context omits miniapp implementation details"
assert_not_contains "$minimal_agents" "@platform/http-client" "minimal AGENTS context omits platform client details"
assert_not_contains "$minimal_agents" "#ifdef / #ifndef" "minimal AGENTS context omits preprocessor details"

minimal_claude=$(sed -n '1,100p' "$HARNESS_ROOT/CLAUDE.md")
assert_contains "$minimal_claude" "AGENTS.md" "minimal CLAUDE context delegates to AGENTS"
assert_contains "$minimal_claude" "/init-specs" "minimal CLAUDE context exposes initialization"
assert_contains "$minimal_claude" ".claude/commands/<name>.md" "minimal CLAUDE context routes playbooks"
assert_contains "$minimal_claude" "dangerous-zones.txt" "minimal CLAUDE context routes dangerous-zone hooks"
assert_contains "$minimal_claude" "缺失时使用兜底" "minimal CLAUDE context preserves dangerous-zone fallback"
assert_contains "$minimal_claude" "verify-harness.sh" "minimal CLAUDE context names the verification hook"
assert_contains "$minimal_claude" "harness 自检时运行测试" "minimal CLAUDE context verifies the harness itself"
assert_contains "$minimal_claude" '项目 specs 为 `active` 时运行 fast profile' "minimal CLAUDE context runs fast profile for active specs"
assert_contains "$minimal_claude" "非 active 时失败关闭" "minimal CLAUDE context fails closed for non-active specs"
assert_contains "$minimal_claude" "不得绕过拦截" "minimal CLAUDE context prohibits bypassing hooks"
assert_not_contains "$minimal_claude" "## 思维方式" "minimal CLAUDE context omits duplicate guidance"

agents_line_count=$(awk 'END { print NR }' "$HARNESS_ROOT/AGENTS.md")
if [ "$agents_line_count" -le 45 ]; then
  pass "AGENTS stays within the minimal line budget"
else
  fail "AGENTS stays within the minimal line budget (expected<=45 actual=$agents_line_count)"
fi

claude_line_count=$(awk 'END { print NR }' "$HARNESS_ROOT/CLAUDE.md")
if [ "$claude_line_count" -le 20 ]; then
  pass "CLAUDE stays within the minimal line budget"
else
  fail "CLAUDE stays within the minimal line budget (expected<=20 actual=$claude_line_count)"
fi

for root_instruction_file in "$HARNESS_ROOT/AGENTS.md" "$HARNESS_ROOT/CLAUDE.md"; do
  root_instruction_name=$(basename "$root_instruction_file")
  if [ -s "$root_instruction_file" ] && [ "$(tail -c 1 "$root_instruction_file" | od -An -t x1 | tr -d '[:space:]')" = "0a" ]; then
    pass "$root_instruction_name ends with LF"
  else
    fail "$root_instruction_name must be non-empty and end with LF"
  fi
done

finish_tests
