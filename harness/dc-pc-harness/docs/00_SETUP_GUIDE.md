# 00_SETUP_GUIDE.md

---
owner: Frontend Team
last_verified: 2026-04-28
status: active
purpose: 指导项目首次接入 Project Harness 时按优先级填写文档，避免一开始就维护过重的模板。
primary_readers:
  - Project Owners
  - Tech Leads
  - AI Agents
related:
  - 00_INDEX.md
  - 01_PROJECT_OVERVIEW.md
  - 02_ARCHITECTURE.md
  - 11_DANGEROUS_AREAS.md
---

## 1. 初始化原则

Project Harness 的目标不是一次性填满所有模板，而是尽快建立可信的项目事实。

优先写：

- 本项目就是这么做
- 本项目不要这么做
- 本项目已经验证过这么做
- 本项目这些地方不能动

少写：

- 理论上可以怎么做
- 多技术栈通用示例
- 和当前项目不一致的理想目录

## 2. 第 1 阶段：必须填写，1 小时内完成

这些文件决定 AI 是否能安全进入项目：

- `agent.md`
- `AGENTS.md`
- `docs/00_INDEX.md`
- `docs/01_PROJECT_OVERVIEW.md`
- `docs/02_ARCHITECTURE.md`
- `docs/03_BUSINESS_DOMAIN.md`
- `docs/11_DANGEROUS_AREAS.md`

最低完成标准：

- 写清真实技术栈和启动命令
- 写清真实目录结构
- 写清核心业务对象和高风险区域
- 明确禁止生成的技术栈、目录、框架和组件库

## 3. 第 2 阶段：开发中补充

这些文件可以随着第一个真实需求逐步补齐：

- `docs/04_CODING_STANDARDS.md`
- `docs/07_API_CONTRACTS.md`
- `docs/08_TASK_PLAYBOOKS.md`

最低完成标准：

- 从当前代码中抽取真实规范
- 只沉淀已经验证过的服务层、类型、错误处理和任务流程
- 不把示例项目的写法直接当作本项目规则

## 4. 第 3 阶段：成熟后沉淀

这些文件适合在项目模式稳定后补齐：

- `docs/05_COMPONENT_PATTERNS.md`
- `docs/06_UI_COMPONENT_GUIDE.md`
- `docs/12_TROUBLESHOOTING.md`
- `docs/examples/`
- `skills/`

最低完成标准：

- 示例必须与当前项目技术栈一致
- 组件模式必须能在真实代码里找到对应实现
- 排障手册必须来自真实问题或已验证流程

## 5. 技术栈收敛规则

落地到真实项目后，必须把通用占位内容收敛为项目专用规则。

示例：

```text
本项目固定使用：
- <Vue 3 / React / 其他>
- <Vite / Next / Nuxt / 其他>
- <Vue Router / React Router / 文件路由 / 其他>
- <Pinia / Redux / Zustand / React Query / 其他>
- <Element Plus / Ant Design / Arco / 自研组件库 / 其他>
- TypeScript

禁止生成：
- 与本项目不一致的组件语法
- 与本项目不一致的路由示例
- 与本项目不一致的状态管理示例
- 与本项目不一致的 UI 组件库示例
```

## 6. 模板真实性校验

每次接入或大版本更新后，至少完成一次校验：

- [ ] 文档中的目录在真实项目中存在
- [ ] 启动命令已在本机或 CI 中验证可运行
- [ ] 组件库、路由、状态管理与 `package.json` 一致
- [ ] API 约定与当前接口实现或正式接口文档一致
- [ ] 危险区已经由项目负责人确认
- [ ] 示例没有引导 AI 生成错误技术栈代码

## 7. 完成定义

v1.1 初始化完成时，Project Harness 应该能回答：

1. 当前项目真实用什么技术栈
2. 新代码应该放在哪些真实目录
3. 哪些目录、框架、组件库、模式禁止生成
4. 哪些区域修改前必须先评估风险
5. 文档中哪些内容已经验证，哪些仍是待确认
