# AGENTS.md — src/components/（模版 · uni-app）
跨页面业务组件（Vue3 + uview-plus）。详见 docs/specs/05_COMPONENT_PATTERNS.md。
- 新建前先搜同类；UI 优先 uview-plus，再项目封装，最后自写
- 不在组件内裸调 API（经 props/composable）
- 页面只做编排：多区块/重复结构/大列表项/弹窗都抽子组件，业务逻辑抽 composable，避免巨型单文件（见 05 拆分原则；单文件 >~500 行应拆）
- src/components/basic/ 是基础公共组件=危险区，改前盘点影响面
