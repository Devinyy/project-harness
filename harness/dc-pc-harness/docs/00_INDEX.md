# 00_INDEX.md

---
owner: Frontend Team
last_verified: 2026-05-08
status: active
purpose: 为开发者提供 docs/ 目录的总入口、阅读顺序、优先级与维护规则，避免文档重复、过时和误读。
primary_readers:
  - Frontend Developers
  - Tech Leads
  - AI Agents
related:
  - 00_SETUP_GUIDE.md
  - 01_PROJECT_OVERVIEW.md
  - 02_ARCHITECTURE.md
  - 03_BUSINESS_DOMAIN.md
  - 04_CODING_STANDARDS.md
  - 05_COMPONENT_PATTERNS.md
  - 06_UI_COMPONENT_GUIDE.md
  - 07_API_CONTRACTS.md
  - 08_TASK_PLAYBOOKS.md
  - 09_TECH_SOLUTION_TEMPLATE.md
  - 10_TECH_SOLUTION_PLAYBOOK.md
  - 11_DANGEROUS_AREAS.md
  - 12_TROUBLESHOOTING.md
---

## 0. 当前初始化状态

| 文档 | 状态 | 说明 |
|------|------|------|
| `agent.md` | ✅ 已填写 | 包含项目技术栈约束（第 0 节） |
| `AGENTS.md` | ✅ 已填写 | 已补充项目速查信息 |
| `00_INDEX.md` | ✅ 已填写 | 本文件 |
| `01_PROJECT_OVERVIEW.md` | ✅ 已填写 | 项目总览、技术栈、启动命令 |
| `02_ARCHITECTURE.md` | ✅ 已填写 | 真实目录结构与分层规则 |
| `03_BUSINESS_DOMAIN.md` | ✅ 已填写 | 核心业务实体与状态 |
| `04_CODING_STANDARDS.md` | ✅ 已填写 | Prettier/ESLint/TS/命名/提交规范 |
| `05_COMPONENT_PATTERNS.md` | ✅ 已填写 | 三层结构、composable 模式、弹层/表单/表格模式 |
| `06_UI_COMPONENT_GUIDE.md` | ✅ 已填写 | dcgj-ui 选型规则，已修正样式方案和目录描述 |
| `07_API_CONTRACTS.md` | ✅ 已填写 | 接口分层、PageResult、mapper 模式、枚举映射、导出 |
| `08_TASK_PLAYBOOKS.md` | ✅ 已填写 | 列表页/详情页/表单/接口/Bug修复步骤 |
| `09_TECH_SOLUTION_TEMPLATE.md` | ✅ 已填写 | 已适配本项目，包含目录映射、API/composable/状态归属等项目规范 |
| `10_TECH_SOLUTION_PLAYBOOK.md` | ✅ 已填写 | 已适配本项目（terminology、api层、composable、packages/触发条件）|
| `11_DANGEROUS_AREAS.md` | ✅ 已填写 | 已补充真实危险区路径 |
| `12_TROUBLESHOOTING.md` | ✅ 已填写 | 已适配本项目（pnpm 命令、微前端排障、token链路、URL状态同步）|

---

## 1. 文档目标

`docs/` 的目标不是"把知识存下来"，而是让开发者能在真正修改代码前快速回答这几个问题：

1. 这个项目是做什么的，边界是什么
2. 当前目录、分层、路由、数据流是怎么组织的
3. 写代码应该遵守什么规范与模式
4. UI 应该如何选型，哪些组件能复用
5. 接口、状态、权限、埋点、异常要怎么处理
6. 哪些地方危险，哪些故障排查有固定套路
7. 什么情况下应该先写技术方案，再进入开发

> 本目录是项目的正式知识源之一。对于架构、约束、模式类问题，优先查文档，不要凭印象开发。

---

## 2. 使用原则

### 2.1 单一事实来源

- 同一主题只维护一份正式文档
- 编号文件是正式版本
- 不建议在仓库中同时维护"编号版"和"无编号版"的同主题正文
- 若必须兼容旧链接，旧文件只保留跳转说明，不再放完整内容

### 2.2 文档优先于猜测

当遇到不确定信息时，按以下顺序处理：

1. 先查 `docs/`
2. 再查代码中的现有实现
3. 再查设计稿、PRD、接口文档
4. 仍不确定时，列出待确认项，不要擅自假设

### 2.3 写代码前先看相关文档

- 禁止在未阅读相关文档的情况下直接修改公共模块
- 禁止因为"赶进度"跳过架构和危险区检查
- 禁止将历史特殊实现误当成标准模式复制扩散

---

## 3. 阅读顺序

### 3.1 第一次接手项目

推荐顺序：

1. `00_SETUP_GUIDE.md`
2. `01_PROJECT_OVERVIEW.md`
3. `02_ARCHITECTURE.md`
4. `03_BUSINESS_DOMAIN.md`
5. `11_DANGEROUS_AREAS.md`
6. `04_CODING_STANDARDS.md`（待填写）
7. `05_COMPONENT_PATTERNS.md`（待填写）
8. `06_UI_COMPONENT_GUIDE.md` + `dcgj-components/COMPONENT_INDEX.md`
9. `07_API_CONTRACTS.md`（待填写）

### 3.2 新增页面 / 功能模块

推荐顺序：

1. `01_PROJECT_OVERVIEW.md`
2. `02_ARCHITECTURE.md`
3. `03_BUSINESS_DOMAIN.md`
4. `05_COMPONENT_PATTERNS.md`（待填写）
5. `06_UI_COMPONENT_GUIDE.md` + `dcgj-components/COMPONENT_INDEX.md`
6. `07_API_CONTRACTS.md`（待填写）
7. `08_TASK_PLAYBOOKS.md`（待填写）
8. `10_TECH_SOLUTION_PLAYBOOK.md`（待填写）

### 3.3 开发前输出技术方案

推荐顺序：

1. `01_PROJECT_OVERVIEW.md`
2. `02_ARCHITECTURE.md`
3. `03_BUSINESS_DOMAIN.md`
4. `06_UI_COMPONENT_GUIDE.md`
5. `07_API_CONTRACTS.md`（待填写）
6. `11_DANGEROUS_AREAS.md`
7. `10_TECH_SOLUTION_PLAYBOOK.md`（待填写）
8. `09_TECH_SOLUTION_TEMPLATE.md`（待填写）

### 3.4 接入或修改 API

推荐顺序：

1. `02_ARCHITECTURE.md`
2. `04_CODING_STANDARDS.md`（待填写）
3. `07_API_CONTRACTS.md`（待填写）
4. `08_TASK_PLAYBOOKS.md`（待填写）
5. `11_DANGEROUS_AREAS.md`

### 3.5 修复线上或复杂故障

推荐顺序：

1. `12_TROUBLESHOOTING.md`（待填写）
2. `11_DANGEROUS_AREAS.md`
3. `02_ARCHITECTURE.md`
4. `07_API_CONTRACTS.md`（待填写）

---

## 4. 文件说明

### `00_SETUP_GUIDE.md`
初始化指南：说明 Project Harness 落地时哪些必须先填、哪些按需启用、如何做真实性校验。

### `01_PROJECT_OVERVIEW.md`
项目总览：大厨管家运营管理平台的业务定位、技术栈、环境、运行方式、外部依赖。

### `02_ARCHITECTURE.md`
架构说明：monorepo 结构、各 app 目录分层、路由组织、微前端通信、请求链路。

### `03_BUSINESS_DOMAIN.md`
业务领域：商家、商品、价格规则等核心实体，状态流转，术语约定。

### `04_CODING_STANDARDS.md`
编码规范：命名、类型、样式、导入、错误处理、注释约定。（待填写）

### `05_COMPONENT_PATTERNS.md`
组件模式：views / composables / components 的职责划分，页面/表单/弹层骨架。（待填写）

### `06_UI_COMPONENT_GUIDE.md`
UI 选型：dcgj-ui 优先原则，弹层/表格/表单/反馈态选型规则。dcgj 组件详情见 `dcgj-components/`。（待填写）

### `07_API_CONTRACTS.md`
接口契约：API 文件组织、mapper/adapter 模式、错误码、分页约定。（待填写）

### `08_TASK_PLAYBOOKS.md`
任务打法：新增列表页、详情页、表单、接口接入的标准步骤。（待填写）

### `09_TECH_SOLUTION_TEMPLATE.md`
技术方案模板：开发前方案文档的标准结构。（待填写）

### `10_TECH_SOLUTION_PLAYBOOK.md`
技术方案行动手册：什么时候必须先出方案。（待填写）

### `11_DANGEROUS_AREAS.md`
危险区：微前端基座、认证 token、路由系统、HTTP 拦截器等高风险区域的修改规范。

### `12_TROUBLESHOOTING.md`
排障手册：启动失败、白屏、token 失效、微前端通信异常等问题排查路径。（待填写）

### `dcgj-components/`
Dcgj UI 组件文档：12 个核心封装组件的 API 说明，见 `dcgj-components/COMPONENT_INDEX.md`。

---

## 5. 文档维护规则

### 5.1 什么时候必须更新文档

出现以下情况时，必须同步更新 `docs/`：

- 新增重要模块或大页面
- 引入新的通用组件模式
- 接口契约、错误码、字段模型发生变化
- 状态管理方案、路由组织方案发生变化
- 新增危险操作区域或重大历史坑点
- 技术方案模板或任务打法有明显升级

### 5.2 更新责任

- 公共文档由前端负责人或指定 owner 维护
- 功能模块的业务知识应由模块 owner 负责更新
- 评审者应在 Code Review / 方案评审中确认文档是否同步更新

### 5.3 更新节奏

建议：

- 每个 sprint 至少检查一次是否过时
- 每次引入新库、新模式、新页面骨架时及时更新
- 每次线上事故复盘后，将可沉淀部分补入 `11` / `12`
