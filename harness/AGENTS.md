# AGENTS.md

本文件是所有 AI 编码 agent 的共享指令（Claude Code / Codex / Cursor / Windsurf）。
Claude Code 用户同时阅读 `CLAUDE.md`。

## 第一步：读取本项目事实

本仓库真实事实以已复核的 `docs/specs/` 为准。Specs 分三种状态：
- `active`：`00_PROJECT_FACTS.md` 存在、没有 `<填写…>` 等占位符，且文档状态均为 `active` → 才能作为真实事实；先读它与 `INDEX.md`，其余按需 `head`/`grep`。
- `draft`：骨架存在但仍有占位符、`draft/template` 状态或 facts 未声明 `active` → 不得当作项目事实，先按 `docs/specs/_RULE.md` 继续填充并人工复核。
- `missing`：`00_PROJECT_FACTS.md` 不存在（哪怕有空 `docs/specs/` 目录）→ 先生成：
  - Claude Code：运行 `/init-specs`
  - Codex / Cursor / Windsurf / 人：运行 `bash scripts/init-specs.sh`（复制骨架）→ 再按 `docs/specs/_RULE.md` 填充占位符

团队两类项目（harness 通用，由 specs 区分）：
- **PC 微前端类**：Vue3 + micro-app + dcgj-ui + `@platform/http-client`（基座 `apps/micro-main` + 子应用）。
- **uni-app 多端类**：uni-app + Vue3 + uview-plus（单 `src/`，`pages.json` 路由，`#ifdef` 条件编译）。

Specs 为 `active` 后，执行可能涉及授权边界的动作前先读 `docs/specs/13_AGENT_POLICY.md`：`Allowed` 可在用户范围内执行，`Blocked` 不执行，`Ask First` 必须取得明确授权。

## 核心原则

1. 先读后写 — 先查现有实现，再决定改哪些文件
2. 优先复用 — 先找同类页面、组件、composable/hook、api/service
3. 不确定就标记 — 用 `// TODO: 待确认` 而非猜测
4. 不要越权 — 不引入新框架/UI 库、不重构公共模块、不改全局配置
5. （uni-app 类）多端意识 — 平台差异用 `#ifdef / #ifndef`

## 禁止行为

- 引入 React / 非约定 UI 库
- 绕过数据层在页面里裸调接口
- 未确认业务含义就修改状态字段、权限判断或渠道分流
- 照模板示例创建项目中不存在的目录或框架用法
- 在没有需求时引入大规模重构
- 为局部需求修改公共组件 / 请求封装 / 认证模块 / 全局配置

> 项目专属禁止项（如 PC 类禁跨 app import / History 路由；uni-app 类禁裸 `uni.request`、禁建 `services/stores/router` 目录、禁把内容图当切图）见 `docs/specs/00_PROJECT_FACTS.md` 与 `04_CODING_STANDARDS.md`。

## 标准流程（所有 agent 可遵循）

> Claude Code 用 slash command 一键触发（`.claude/commands/`）；Codex / Cursor / Windsurf 没有 slash command，但**遵循下面同一套步骤**。先读 `docs/specs/00_PROJECT_FACTS.md` 确认项目类型与命令。

- **新建页面**（`/new-page`）：`head -40 docs/specs/02_ARCHITECTURE.md` → 搜同类页面作骨架（PC `apps/*/src/views/*.vue`；uni-app `src/pages/<模块>/<xxx>-page.vue`）→ 确认路由/数据来源/状态/权限 → **拆分预判**（页面=容器+子组件：多区块/重复结构/大列表项/弹窗各自成组件，业务逻辑抽 `useXxxPage` composable，避免巨型单文件，见 `05_COMPONENT_PATTERNS.md`「拆分原则」）→ Vue3 SFC + 对应 UI 库，覆盖 loading/empty/error → 数据走项目请求封装 → **uni-app 必须登记 `src/pages.json`** → 跑类型检查命令。
- **排障**（`/debug`）：分层（渲染/数据/接口/配置/构建）→ `grep` 收集证据（不 `cat` 全文）→ 涉及基座/公共先读 `11_DANGEROUS_AREAS.md` → 列 ≤3 个根因各附验证 → 最小改动修复 → 跑类型检查验证 → 列回归范围。连续 3 次失败则停止报告。
- **重构**（`/refactor`）：先读 `11_DANGEROUS_AREAS.md` 确认是否危险区 → 读目标代码理解依赖 → 列计划（改哪些/每步/风险）→ 逐步改、每步跑类型检查 → `git diff --stat` 核对范围。不为"优雅"大改历史代码、不把局部需求上升为全局基础设施修改。
- **代码审查**（`/review`）：定范围（给定文件或 `git diff --name-only HEAD~1`）→ 逐文件 `grep` 查：危险区影响、框架红线、重复造轮子、分层违规、组件粒度（巨型文件 >~500 行 / 未拆分多区块页面）、类型安全、响应式副作用、（uni-app）多端与 box-sizing → 输出风险等级 + 问题清单 + 待确认项。
- **技术方案**（`/tech-solution`）：按需读 `02/03/07` 相关段落 → 搜现有实现列复用点 → 输出：需求理解 / 技术选型(为什么) / 文件清单 / 数据流 / 风险与应对 / 待确认项。

每个流程的完整版见 `.claude/commands/<name>.md`（任意 agent 都可直接打开当 playbook 读）。

## 危险区

涉及 route/router/auth/token/interceptor/permission/build/config 等关键词时，先读 `docs/specs/11_DANGEROUS_AREAS.md`。危险路径清单在 `docs/specs/dangerous-zones.txt`（驱动 hooks）。

## 按需参考

`docs/specs/` 下，不要全量加载，按需 `head`/`grep`（先看 `INDEX.md`）：
`00_PROJECT_FACTS` 事实 / `02_ARCHITECTURE` 架构 / `03_BUSINESS_DOMAIN` 业务 / `04_CODING_STANDARDS` 规范 / `05_COMPONENT_PATTERNS` 组件 / `06_UI_COMPONENT_GUIDE` UI / `07_API_CONTRACTS` 接口 / `11_DANGEROUS_AREAS` 危险区 / `12_TROUBLESHOOTING` 排障 / `13_AGENT_POLICY` 权限边界。

PC 端色号、字号、组件主题 token 按需查 `docs/token-specs/README.md`、`docs/token-specs/Light.tokens.json`、`docs/token-specs/antd-vue-theme.ts`；后续 UI 还原不要绕过 token 手写临时值。
