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

finish_tests
