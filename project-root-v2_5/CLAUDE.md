# CLAUDE.md

## 项目事实（首次接入时必填）

- 技术栈：`<例: React 18 + TypeScript + Vite + Ant Design>`
- 包管理器：`<例: pnpm>`
- 源码根目录：`<例: src/>`
- 启动命令：`<例: pnpm dev>`
- 测试命令：`<例: pnpm test>`
- 类型检查：`<例: pnpm tsc --noEmit>`
- lint 命令：`<例: pnpm lint>`

## 目录归属（按真实项目填写）

- `src/pages/` — 路由级页面
- `src/components/` — 业务组件
- `src/shared/` — 跨模块复用（hooks、utils、类型）
- `src/services/` — API 调用层
- `src/stores/` — 全局状态
- 禁止创建的目录：`<例: app/、features/>`

## 硬规则

- 先读代码再改代码，先找现有实现再写新的
- 不要引入项目中不存在的框架、库、命名方式
- 不要为局部需求修改公共组件或全局配置
- 不确定的业务含义标记 `// TODO: 待确认`，不要猜
- 类型完整，不留 `any`
- 所有组件覆盖 loading / empty / error 态
- service 层与页面层职责分离，不在页面裸调接口
- commit 遵循 Conventional Commits

## 危险区（改动前必须确认影响面）

路由、权限守卫、请求拦截器、全局样式、基础组件、构建配置。
详见 `docs/specs/11_DANGEROUS_AREAS.md`。

## 按需查阅

项目详细规格文档在 `docs/specs/` 目录下，遇到不确定的问题时用 `cat` 查阅，不要预加载。
