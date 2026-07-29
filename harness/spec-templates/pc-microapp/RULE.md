# Flavor 规则：PC 微前端类（如 dc-platform）

适用：Vue 3 + `@micro-zoe/micro-app` 微前端 monorepo + dcgj-ui + `@platform/http-client`。
具体值（端口/子应用名/key）必须从当前仓库取证，本规则给结构与典型形态。

## 探索重点
- `pnpm-workspace.yaml` / `apps/*` / `packages/*`：基座（通常 `apps/micro-main`）与子应用清单、端口（各 `vite.config.ts` 的 server.port）
- `apps/micro-main/src/`：main.ts、App.vue、bootstrap/、micro/(registry/runtime/start)、router/、permission*、store/modules/{permission,user}、request/、config/domain、style/
- `packages/`：http-client(拦截器/refresh)、micro-bridge(IPC BridgeActions)、shared-types/shared-utils/auth-session
- 认证：token 的 localStorage key、client_platform 头、401/471 refresh、预刷新阈值
- UI：dcgj-ui 版本与注册（install-ui-components）

## 各文档要点
- 00：栈=Vue3+Vite+Pinia+Vue Router(Hash)+dcgj-ui+micro-app+@platform/http-client；命令 pnpm run validate(vue-tsc)/build:*；别名 @→src、@platform/*→packages/*/src；token key、API env。禁止：React/JSX/TSX/其它 UI 库、裸 axios/fetch、跨 app import、History 路由、改 token key。
- 02：基座+子应用表(名/端口/职责)、micro 注册与 URL 映射、Hash+动态路由、@platform/* 依赖。
- 03：各子应用业务域、权限模型(hasPerm/permissionHash)。
- 06：dcgj-ui 优先，列常用组件(DcgjTable/DcgjFormPro…)，生成 dcgj-components/ 索引。
- 11：P0=基座启动链路、micro 注册与通信、认证/token、路由与权限守卫、packages/http-client 拦截器、@platform/* 共享包、构建配置；P1=全局 Provider/样式。

## dangerous-zones.txt：见同目录模版，按实际增删。
## 目录级 AGENTS：apps/AGENTS.md、apps/micro-main/AGENTS.md(基座危险区)、packages/AGENTS.md(共享包危险区)。
## 验证档位
- fast：从 package.json 取证 typecheck/validate 命令写入 `verify.cmd`；Vue 项目用 vue-tsc，不是 tsc。
- full：在 `verify.full.cmd` 中记录真实存在的 lint、build 和 test/test:* 脚本；没有对应脚本就写注释说明，不编造。
- Stop hook 只运行 fast；人工/CI 用 `bash scripts/run-verification-profile.sh full`。
