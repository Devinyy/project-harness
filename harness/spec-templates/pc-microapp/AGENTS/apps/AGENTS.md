# AGENTS.md — apps/（模版 · PC 微前端）
基座 micro-main + 子应用 app-*。
- 页面 `app-*/src/views/`，组件 `app-*/src/components/`，新建前先搜同类
- Vue3 SFC + dcgj-ui，覆盖 loading/empty/error；请求经 @platform/http-client，禁裸 axios/fetch
- 页面只做编排：多区块/重复结构/大列表项/弹窗都抽子组件，业务逻辑抽 composable/store，避免巨型单文件（见 05 拆分原则；单文件 >~500 行应拆）
- 禁跨 app import（走 @platform/* 或 micro-bridge）；按钮权限走 `<例 hasPerm>`
- 详见 docs/specs/02_ARCHITECTURE.md
