# AGENTS.md — apps/（模版 · PC 微前端）
基座 micro-main + 子应用 app-*。
- 页面 `app-*/src/views/`，组件 `app-*/src/components/`，新建前先搜同类
- Vue3 SFC + dcgj-ui，覆盖 loading/empty/error；请求经 @platform/http-client，禁裸 axios/fetch
- 禁跨 app import（走 @platform/* 或 micro-bridge）；按钮权限走 `<例 hasPerm>`
- 详见 docs/specs/02_ARCHITECTURE.md
