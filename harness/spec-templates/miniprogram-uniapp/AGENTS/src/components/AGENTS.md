# AGENTS.md — src/components/（模版 · uni-app）
跨页面业务组件（Vue3 + uview-plus）。详见 docs/specs/05_COMPONENT_PATTERNS.md。
- 新建前先搜同类；UI 优先 uview-plus，再项目封装，最后自写
- 不在组件内裸调 API（经 props/composable）
- src/components/basic/ 是基础公共组件=危险区，改前盘点影响面
