# 00_INDEX.md

---
owner: Frontend Team
last_verified: 2026-04-21
status: active
purpose: 为开发者提供 docs/ 目录的总入口、阅读顺序、优先级与维护规则，避免文档重复、过时和误读。
primary_readers:
  - Frontend Developers
  - Tech Leads
  - AI Agents
related:
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

## 1. 文档目标

`docs/` 的目标不是“把知识存下来”，而是让开发者能在真正修改代码前快速回答这几个问题：

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
- 不建议在仓库中同时维护“编号版”和“无编号版”的同主题正文
- 若必须兼容旧链接，旧文件只保留跳转说明，不再放完整内容

### 2.2 文档优先于猜测

当遇到不确定信息时，按以下顺序处理：

1. 先查 `docs/`
2. 再查代码中的现有实现
3. 再查设计稿、PRD、接口文档
4. 仍不确定时，列出待确认项，不要擅自假设

### 2.3 写代码前先看相关文档

- 禁止在未阅读相关文档的情况下直接修改公共模块
- 禁止因为“赶进度”跳过架构和危险区检查
- 禁止将历史特殊实现误当成标准模式复制扩散

---

## 3. 阅读顺序

### 3.1 第一次接手项目

推荐顺序：

1. `01_PROJECT_OVERVIEW.md`
2. `02_ARCHITECTURE.md`
3. `03_BUSINESS_DOMAIN.md`
4. `04_CODING_STANDARDS.md`
5. `05_COMPONENT_PATTERNS.md`
6. `06_UI_COMPONENT_GUIDE.md`
7. `07_API_CONTRACTS.md`
8. `11_DANGEROUS_AREAS.md`

### 3.2 新增页面 / 功能模块

推荐顺序：

1. `01_PROJECT_OVERVIEW.md`
2. `02_ARCHITECTURE.md`
3. `03_BUSINESS_DOMAIN.md`
4. `05_COMPONENT_PATTERNS.md`
5. `06_UI_COMPONENT_GUIDE.md`
6. `07_API_CONTRACTS.md`
7. `08_TASK_PLAYBOOKS.md`
8. `10_TECH_SOLUTION_PLAYBOOK.md`

### 3.3 开发前输出技术方案

推荐顺序：

1. `01_PROJECT_OVERVIEW.md`
2. `02_ARCHITECTURE.md`
3. `03_BUSINESS_DOMAIN.md`
4. `06_UI_COMPONENT_GUIDE.md`
5. `07_API_CONTRACTS.md`
6. `11_DANGEROUS_AREAS.md`
7. `10_TECH_SOLUTION_PLAYBOOK.md`
8. `09_TECH_SOLUTION_TEMPLATE.md`

### 3.4 接入或修改 API

推荐顺序：

1. `02_ARCHITECTURE.md`
2. `04_CODING_STANDARDS.md`
3. `07_API_CONTRACTS.md`
4. `08_TASK_PLAYBOOKS.md`
5. `11_DANGEROUS_AREAS.md`

### 3.5 修复线上或复杂故障

推荐顺序：

1. `12_TROUBLESHOOTING.md`
2. `11_DANGEROUS_AREAS.md`
3. `02_ARCHITECTURE.md`
4. `07_API_CONTRACTS.md`
5. `08_TASK_PLAYBOOKS.md`

---

## 4. 文件说明

### `01_PROJECT_OVERVIEW.md`
项目总览：项目做什么、解决什么问题、技术栈、环境、运行方式、外部依赖、发布方式。

### `02_ARCHITECTURE.md`
架构说明：目录结构、分层职责、路由组织、状态管理、请求链路、环境隔离与扩展规则。

### `03_BUSINESS_DOMAIN.md`
业务领域：角色、核心实体、状态流转、术语解释、业务规则、边界与易混淆概念。

### `04_CODING_STANDARDS.md`
编码规范：命名、类型、样式、导入、错误处理、注释、测试、可维护性与 AI 输出限制。

### `05_COMPONENT_PATTERNS.md`
组件模式：pages / features / shared / ui 的职责划分、组件目录模板、常见页面/表单/弹层模式。

### `06_UI_COMPONENT_GUIDE.md`
UI 选型：按钮、表格、表单、弹层、状态反馈、布局和组件复用规则。

### `07_API_CONTRACTS.md`
接口契约：service 层组织方式、请求响应模型、字段映射、错误码、分页、缓存、重试、Mock。

### `08_TASK_PLAYBOOKS.md`
任务打法：新增列表页、详情页、表单、接口接入、权限点、路由、重构、Bug 修复的标准步骤。

### `09_TECH_SOLUTION_TEMPLATE.md`
技术方案模板：开发前方案文档的标准结构。

### `10_TECH_SOLUTION_PLAYBOOK.md`
技术方案行动手册：什么时候必须先出方案，方案怎么推导、自检什么。

### `11_DANGEROUS_AREAS.md`
危险区：对路由、权限、请求拦截器、公共组件、全局样式、构建配置等高风险区域的修改规范。

### `12_TROUBLESHOOTING.md`
排障手册：启动失败、白屏、权限异常、接口异常、状态不同步、构建失败、性能问题等问题的排查路径。

### `examples/`
示例目录：提供已填充的示例，帮助开发者和 AI 理解“好文档”“好方案”“好拆解”长什么样。

---

## 5. 文档维护规则

### 6.1 什么时候必须更新文档

出现以下情况时，必须同步更新 `docs/`：

- 新增重要模块或大页面
- 引入新的通用组件模式
- 接口契约、错误码、字段模型发生变化
- 状态管理方案、路由组织方案发生变化
- 新增危险操作区域或重大历史坑点
- 技术方案模板或任务打法有明显升级

### 6.2 更新责任

- 公共文档由前端负责人或指定 owner 维护
- 功能模块的业务知识应由模块 owner 负责更新
- 评审者应在 Code Review / 方案评审中确认文档是否同步更新

### 6.3 更新节奏

建议：

- 每个 sprint 至少检查一次是否过时
- 每次引入新库、新模式、新页面骨架时及时更新
- 每次线上事故复盘后，将可沉淀部分补入 `11` / `12`

---

## 6. 建议的文档元信息

每份文档顶部建议保留如下元信息：

```yaml
---
owner: Frontend Team
last_verified: 2026-04-21
status: active
purpose: 这份文档解决什么问题
primary_readers:
  - Frontend Developers
  - AI Agents
related:
  - 02_ARCHITECTURE.md
  - 04_CODING_STANDARDS.md
---
```

含义：

- `owner`：谁负责维护
- `last_verified`：最后一次确认内容仍有效的日期
- `status`：active / draft / deprecated
- `purpose`：文档使命，减少“看不懂这份文档有什么用”
- `primary_readers`：主要读者
- `related`：相关文档，方便跳转

---

## 7. 建议的新增原则

新增文档前，先回答：

1. 这份文档解决的是不是新的问题
2. 能不能合并到已有文档而不是再开一份
3. 是否会和现有内容产生重叠
4. 是否有明确 owner 和更新时机

满足以下条件再新增文档：

- 主题足够稳定
- 内容不会与现有文档明显重叠
- 对多人协作或 AI 执行有显著帮助
- 能明确落入一个维护责任域

---

## 8. 建议的 examples 目录

推荐最少包含以下示例：

```text
examples/
├── README.md
├── EXAMPLE_FILLED_TECH_SOLUTION.md
├── EXAMPLE_API_CONTRACT_ENTRY.md
├── EXAMPLE_TASK_BREAKDOWN_ADD_LIST_PAGE.md
└── EXAMPLE_BUSINESS_GLOSSARY.md
```

这些示例的目标不是成为项目事实，而是展示“填得好的文档长什么样”。

---

## 9. 最后提醒

这套 docs 的真正价值，不在于“文档数量多”，而在于：

- 让开发者在进入代码前先理解约束
- 让所有开发参与者先理解约束，再生成或修改代码
- 让团队将隐性经验转成显性知识
- 让复杂任务在一开始就减少返工与走偏
