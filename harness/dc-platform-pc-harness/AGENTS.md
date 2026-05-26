# AGENTS.md

本文件是通用 AI 编码助手入口。

---

## 本项目速查

**项目**：大厨管家运营管理平台  
**技术栈**：Vue 3 + TypeScript + Vite + Pinia + Vue Router 4（Hash） + dcgj-ui + @micro-zoe/micro-app  
**结构**：pnpm monorepo，主基座 `micro-main`（端口 3000）+ 子应用 `app-merchant`（3002）/ `app-product`（3003）/ `app-system`（3001）

**禁止**：
- React / JSX / Element Plus / Redux / Vuex
- 裸 Axios 实例或 fetch（必须使用 `@platform/http-client`）
- 跨 apps 直接 import（只能通过 `@platform/*` 包）
- History 模式路由（统一 Hash 模式）

---

## 开始任何开发、排障、重构或方案输出前，请先阅读：

1. `agent.md`（重点读第 0 节技术栈约束）
2. `docs/00_SETUP_GUIDE.md`
3. `docs/00_INDEX.md`
4. `docs/manifest.json`

核心红线：

- 不要照模板创建真实项目中不存在的目录
- 不要把示例中的 React / Vue / UI 库写法直接套到当前项目
- 不要在未确认技术栈和目录结构前生成代码
- 涉及路由、权限、请求拦截器、基础组件、全局样式、构建配置时，先读 `docs/11_DANGEROUS_AREAS.md`

更完整的行为规则见 `agent.md`。
