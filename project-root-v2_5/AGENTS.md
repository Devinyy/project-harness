# AGENTS.md

本文件是所有 AI 编码 agent 的共享指令（Claude Code / Codex / Cursor / Windsurf）。

## 核心原则

1. 先读后写 — 先查现有实现，再决定改哪些文件
2. 优先复用 — 先找同类页面、组件、hook、service
3. 不确定就标记 — 用 `// TODO: 待确认` 而非猜测
4. 不要越权 — 不引入新框架、不重构公共模块、不改全局配置

## 禁止行为

- 修改公共基础组件以满足局部需求
- 绕过 service 层在页面裸调接口
- 未确认业务含义就修改状态字段或权限判断
- 照模板示例创建项目中不存在的目录或框架用法
- 在没有需求时引入大规模重构

## 危险区触发词

遇到以下关键词时，先查 `docs/specs/11_DANGEROUS_AREAS.md`：
route, router, guard, auth, token, permission, interceptor, http client,
shared ui, base component, global style, theme, build, config, provider

## 按需参考

项目规格文档在 `docs/specs/` 下，不要全量加载，按需 `cat` 查阅：
- 架构疑问 → `02_ARCHITECTURE.md`
- 业务术语 → `03_BUSINESS_DOMAIN.md`
- 编码规范 → `04_CODING_STANDARDS.md`
- 组件模式 → `05_COMPONENT_PATTERNS.md`
- UI 选型 → `06_UI_COMPONENT_GUIDE.md`
- 接口接入 → `07_API_CONTRACTS.md`
- 排障 → `12_TROUBLESHOOTING.md`
