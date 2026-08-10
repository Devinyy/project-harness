# 00_PROJECT_FACTS.md（模版骨架 · PC 微前端 flavor）
> 🧩 A 精炼版：`<...>` 为占位符，按真实代码填充；固定常量已给出，仍需核对版本/路径。
---
owner: Frontend Team
last_verified: <生成时填写>
status: template
purpose: 项目事实速查（栈/命令/目录/认证），agent 首先阅读这份
---

## 项目事实
- 项目：`<package.json name，例 dc-platform-new>`（<一句话定位>）
- 技术栈（固定）：Vue 3 + TypeScript + Vite + Pinia + Vue Router 4（**Hash `createWebHashHistory`**）
- UI 库：**dcgj-ui**（基于 ant-design-vue 4，版本 `<填写>`）
- 微前端：`@micro-zoe/micro-app`（iframe 隔离，版本 `<填写>`）
- HTTP：`@platform/http-client`（`import request from '@/request'`）
- 包管理器：`pnpm`（monorepo `<版本>`；pnpm-workspace.yaml）
- 源码根：基座 `apps/micro-main/src/`，子应用 `apps/app-*/src/`，共享包 `packages/*/src/`
- 别名：`@ → src`，`@platform/* → packages/*/src`
- 子应用与端口：`<逐个填写，例 micro-main 3000 / app-system 3001 / app-merchant 3002 / ...>`
- 启动 `pnpm dev`；构建 `<例 pnpm run build:dev|test|pre|prod>`
- 类型检查/校验：`<例 pnpm run validate>`（底层 **vue-tsc --noEmit**，不是 tsc）
- 认证：token localStorage key `<例 user-auth>`；头 `Authorization`+`client_platform`（`<取值>`）；refresh `<策略>`
- API 基址 env：`<例 VITE_APP_API_URL>`

## 目录归属
- `apps/*/src/views/` 页面 ｜ `apps/*/src/components/` 业务组件 ｜ `apps/*/src/request/` 请求 ｜ `apps/*/src/store/` Pinia
- `apps/micro-main/` ⚠️ 基座（危险区）｜ `packages/*/src/` ⚠️ @platform/* 共享包（危险区）

## 硬规则（固定）
- 禁 React/JSX/TSX/其它 UI 库；禁裸 axios/fetch（走 @platform/http-client）；禁跨 app import（走 @platform/* 或 micro-bridge）；禁 History 路由；不为局部需求改基座/packages。
- 危险区详见 `11_DANGEROUS_AREAS.md`。
