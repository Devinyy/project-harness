# 09_TECH_SOLUTION_TEMPLATE.md

---
owner: Frontend Team
last_verified: 2026-05-08
status: active
purpose: 定义"开发前前端技术方案"的标准结构，确保需求在开发前完成影响面分析、组件复用判断、数据流设计与风险识别。
primary_readers:
  - Frontend Developers
  - Tech Leads
  - AI Agents
related:
  - 02_ARCHITECTURE.md
  - 03_BUSINESS_DOMAIN.md
  - 04_CODING_STANDARDS.md
  - 06_UI_COMPONENT_GUIDE.md
  - 07_API_CONTRACTS.md
  - 10_TECH_SOLUTION_PLAYBOOK.md
  - 11_DANGEROUS_AREAS.md
---

> 使用方式：
>
> - 每个需要技术方案的需求，开发前基于本模板生成一份方案文档
> - 未涉及的章节写 `N/A`，不要删除章节
> - 不允许只写结论不写依据
> - "不确定"的内容列在第 14 节，不要默认假设

---

## 0. 本项目使用说明

本模板已适配 **大厨管家运营管理平台（dc-platform-new）** 项目规范，使用前注意：

| 模板术语 | 本项目对应位置 |
|----------|---------------|
| 页面层 / views | `src/views/{context}/` |
| 业务组件 | `src/components/{domain}/{context}/` 或 `src/components/ops/{domain}/` |
| 通用组件 | `src/components/common/` |
| 逻辑层 / composable | `src/composables/` 或 `src/composables/ops/` |
| API 层 | `src/api/domain.ts` + `domain.definitions.ts` + `domain.xxx.mapper.ts` |
| 类型层 | `src/types/domain.ts` |
| 状态层 | `src/stores/`（子应用）或 `src/store/modules/`（micro-main，危险区） |

**固定约束**（写方案前先确认）：

- 所有 UI 组件从 `dcgj-ui` 导入，禁止直接用 `ant-design-vue`
- 路由使用 Hash 模式，在子应用 `src/router/index.ts` 中注册
- API 请求通过 `@platform/http-client` 的 `request`，禁止裸 axios
- 跨 app 共享逻辑需走 `packages/` 包，不能直接 `import` 另一个 app
- 涉及 `11_DANGEROUS_AREAS.md` 中的 P0 区域须先经技术评审

---

## 1. 元信息

- **需求名称**：
- **需求 / 任务 ID**：
- **方案作者**：
- **评审人**：
- **创建日期**：
- **计划开发日期**：
- **当前状态**：`draft` / `review` / `approved` / `archived`
- **关联文档**：
  - PRD：
  - 设计稿：
  - API 文档（Swagger / Apifox）：
  - 相关历史方案：
  - 相关代码目录：

---

## 2. 背景与目标

### 2.1 需求背景

说明为什么做这个需求，当前痛点是什么，业务希望达成什么结果。

### 2.2 目标

- 用户能完成哪些关键操作
- 前端侧必须支持哪些业务规则
- 这是已有能力的扩展，还是全新模块

### 2.3 非目标

明确本次**不做**的内容，避免范围扩散：

- 本期不改动 ___
- 本期不处理 ___

---

## 3. 影响范围

| 维度 | 说明 |
|------|------|
| 涉及 App | app-product / app-merchant / app-system / micro-main |
| 涉及角色 | |
| 新增页面 | （路由路径） |
| 修改页面 | |
| 新增组件 | |
| 修改组件 | |
| 新增接口 | |
| 修改接口 | |
| 新增路由 | |
| 新增/修改 Store | （注：轻易不动 micro-main 的 store，属 P0） |
| 涉及危险区 | 是/否，若是列出具体路径 |

---

## 4. 用户流程

### 4.1 主流程

按步骤描述用户操作路径：

1. 从哪里进入
2. 默认看到什么
3. 输入/选择什么
4. 触发什么动作
5. 页面如何反馈
6. 异常时如何处理

### 4.2 关键状态列举

- 初始加载中
- 空态（无数据）
- 无权限
- 编辑态 / 查看态（如适用）
- 提交中（按钮 disabled + loading）
- 提交成功
- 接口异常

---

## 5. 信息架构与路由设计

### 5.1 页面区块划分

说明页面由哪些区域组成：

- DcgjBread（面包屑，哪一级）
- 筛选区（使用 `DcgjFormPro` 还是手写）
- 数据展示区（`DcgjTable` / 卡片 / 列表）
- 弹层（Modal 还是 `DcgjDrawer`，宽度）
- 操作区（行内操作 / 底部固定栏 / 页头按钮）

### 5.2 路由

- 路由路径：`/your-domain/list`
- 参数：（id / query params）
- 注册位置：`src/router/index.ts`（子应用自己）
- 菜单：在主基座后台配置，前端**不硬编码**

### 5.3 查询状态同步策略

说明筛选/分页是否与 URL 同步（列表页应同步）：

- URL 参数作为真值：`watch(route.query)` → 触发请求
- 筛选提交：`router.replace({ query: ... })` 而不是直接修改 reactive
- pageNum 重置时机：筛选、排序变化时重置为 1

---

## 6. 组件方案

### 6.1 dcgj-ui 组件选型

| 区域 | 选用组件 | 理由 |
|------|----------|------|
| 表格 | `DcgjTable` | |
| 表单 | `DcgjFormPro` / antd `Form` | 字段少用 antd，字段多用 DcgjFormPro |
| 抽屉 | `DcgjDrawer` | |
| 描述展示 | `DcgjDesc` | |
| 内容卡片 | `DcgjContentCard` | |
| 状态标签 | `StatusTag`（`components/common/`）| |
| 金额展示 | `DcgjNumber` 或 `PriceText` | |

### 6.2 复用 / 新增决策

- **直接复用**（已有且满足需求）：
- **需要扩展**（已有但需加 prop 或修改逻辑）：
- **必须新增**（说明为什么不能复用）：
- **不抽象**（只用一次，或语义差异大）：

### 6.3 交互细节

覆盖以下内容（与设计稿对齐）：

- 默认值：
- 禁用条件：
- 表格行操作超 3 个时如何折叠：
- 二次确认场景（下架、删除等危险操作）：
- 操作成功反馈（toast 文案 / 跳转）：
- 空态文案：
- 超长文本/溢出处理：

---

## 7. 数据流设计

### 7.1 数据流链路

本项目标准链路：

```
后端接口
  ↓ request（@platform/http-client）
api/domain.ts（接口函数 + mapper）
  ↓
composable（useOps{Domain}ListQuery / use{Domain}Query 等）
  ↓ reactive state
views（解构 composable）
  ↓ props / emit
components（纯展示/交互）
```

说明本需求的链路是否有偏差：

### 7.2 请求时机

- 首屏加载：`watch(route.query, ..., { immediate: true })`
- 筛选触发：`router.replace` → watch 触发
- 分页触发：`changePage` → `router.replace` → watch 触发
- 手动刷新：直接调 composable 内 `fetchList()`
- 提交成功后刷新：composable 内 `await fetchList()` 或跳转列表页

### 7.3 状态归属

| 状态类型 | 归属位置 | 说明 |
|----------|----------|------|
| 列表数据 / loading / total | composable（`ref`）| |
| 查询条件 | composable（`reactive`）+ URL | URL 为真值 |
| 草稿筛选条件 | composable（`draftQuery`）| 点搜索才提交 |
| 弹层 open / loading | views 层（`ref`）| 不放 composable |
| 当前操作对象（如 offlineRecord）| views 层（`ref`）| |
| 跨页面共享状态 | Pinia store（`src/stores/`）| 仅需跨页面时才用 |

### 7.4 并发与边界

- 是否需要防抖（远程搜索下拉必须）：
- 是否可能重复提交（提交中禁用按钮）：
- 快速切换 Tab 时是否会产生竞态（通常 watch 覆盖即可）：
- catch 时是否需要重置数据（列表: `records = []`、`total = 0`）：

---

## 8. API 与字段映射

### 8.1 接口清单

| 接口 | 方式 | URL | 用途 | 是否已有 api 函数 |
|------|------|-----|------|------------------|
| | POST | /ops/v1/xxx/query | 列表查询 | 是/否 |
| | POST | /ops/v1/xxx/detail | 详情 | 是/否 |
| | POST | /ops/v1/xxx/save | 创建/编辑 | 是/否 |

> 参照 `07_API_CONTRACTS.md` 第 3 节的文件组织规范新增 api 文件。

### 8.2 字段映射

前端 UI 字段 → 后端 DTO 字段（在 mapper 中处理，不要在 composable 或 views 里转换）：

| UI 字段 | 后端字段 | 转换逻辑 |
|---------|----------|----------|
| `status: 'ENABLED'` | `status: 1` | mapper 转 number |
| `pageNum` | `pageNum` | 同名，无需转换 |
| 空字符串 | 不传 | `stripEmpty` 过滤 |

### 8.3 枚举映射

后端返回数字枚举时，mapper 转为前端字符串字面量（参见 `07_API_CONTRACTS.md` 第 5 节）：

| 后端值 | 前端 UI 类型 | 标签常量 |
|--------|-------------|----------|
| 1 | `'PENDING'` | `XX_STATUS_LABEL['PENDING']` |

### 8.4 错误处理

- 哪些业务错误码需要字段级提示（非 toast）：
- 哪些操作需要二次确认弹窗：
- 接口超时/500 时用户可见反馈：

### 8.5 待确认项

把接口不确定点列出（写在第 14 节也可）：

- 分页参数名是否是 `pageNum` / `pageSize`（默认是，例外要确认）：
- 枚举值来源（后端文档还是前端自定义）：
- 空值语义（null 还是不传）：

---

## 9. 状态管理方案

### 9.1 是否需要 Pinia Store

结合以下判断（见 `08_TASK_PLAYBOOKS.md` Playbook F）：

- [ ] 状态需要跨多个 composable 或页面共享
- [ ] 状态需要在路由切换后保持
- [ ] 状态需要被多个非父子组件订阅

如果三条均不符合，**不要新增 store**，用 composable 的 reactive 即可。

### 9.2 Store 设计（如需新增）

- Store 名称：
- 文件位置：`src/stores/`（子应用）或 `src/store/modules/`（micro-main，慎改）
- State 字段：
- Actions：
- 初始化时机：
- 清理时机（路由守卫 / `onUnmounted`）：
- 是否可能残留上一次状态（需要 `$reset()`）：

---

## 10. 权限与埋点

### 10.1 权限

- 页面可见权限（由主基座菜单配置控制）：
- 操作按钮权限（如需按钮级）：
- 无权限时表现：

### 10.2 埋点（如有）

- 页面曝光：
- 关键按钮点击（筛选/提交/导出/审核）：
- 提交成功/失败：

---

## 11. 风险评估

### 11.1 业务风险

- 需求规则是否有歧义（列出不确定点）：
- 历史数据是否存在脏数据风险：
- 状态机是否复杂（多状态跳转）：

### 11.2 技术风险

| 风险 | 影响 | 应对 |
|------|------|------|
| 依赖现有组件（改动有连锁影响）| | |
| 接口响应不稳定 | | |
| 枚举值/字段名与后端文档不符 | | |
| 涉及危险区（见 `11_DANGEROUS_AREAS.md`）| | |

### 11.3 回滚策略

- 如何在不影响主干的情况下隔离本次改动：
- 是否需要功能开关：

---

## 12. 实现拆分

### 12.1 开发任务列表

按可交付粒度拆分（能独立 PR 或独立测试的粒度）：

1. 路由 + 页面骨架（views + router）
2. API 层（api/domain.ts + mapper + types/）
3. Composable（数据请求 + 状态管理）
4. 业务组件开发（SearchForm / Table / Modal 等）
5. 交互细节（loading / empty / error / confirm）
6. 权限 / 埋点
7. 自测 + 联调 + 回归

### 12.2 预计改动文件清单

```text
src/
├── router/index.ts                          # 新增路由
├── views/{context}/{domain}/
│   ├── list.vue                             # 新增/修改
│   ├── detail.vue
│   └── form.vue
├── components/{domain}/                     # 新增业务组件
│   ├── {domain}SearchForm.vue
│   ├── {domain}Table.vue
│   └── {domain}XxxModal.vue
├── components/common/                       # 如有跨域复用组件
├── composables/[ops/]                       # 新增 composable
│   └── useOps{Domain}ListQuery.ts
├── api/
│   ├── domain.ts                            # 接口函数
│   ├── domain.definitions.ts               # 后端 DTO 类型
│   └── domain.xxx.mapper.ts                # 字段映射
├── api/__contracts__/                       # 编译期类型契约（可选）
├── types/
│   └── domain.ts                           # UI 类型
└── stores/                                 # 如需新增 store
```

### 12.3 自测 / 联调重点

- 列表加载 / 空态 / loading：
- 筛选 + pageNum 重置：
- 分页翻页 + 删除最后一条退回上一页：
- 表单回填 + 提交成功跳转：
- 弹层打开/关闭/确认 loading：
- 回归受影响的历史页面：

---

## 13. 验收标准

用户侧结果验收（对照 PRD 和设计稿）：

- [ ] 用户可从指定入口进入功能
- [ ] 列表加载、空态、异常均有正确表现
- [ ] 筛选正确，pageNum 重置正确
- [ ] 表单校验正确，后端错误映射到字段
- [ ] 提交成功后反馈正确（toast + 跳转）
- [ ] 弹层打开/关闭/防重复提交正确
- [ ] 状态标签与现有页面一致（走 StatusTag）
- [ ] 不破坏历史页面的现有功能

---

## 14. 开发前待确认问题

列出所有阻塞开发或可能导致返工的问题：

1. （API 字段）
2. （业务规则）
3. （设计稿细节）

> 未确认的内容不能假设为"按常规"。如必须先开发，需在此注明临时假设及后续补正方式。

---

## 15. 最终结论

用 5-8 句话总结本方案核心判断：

- 采用什么页面结构（路由 + 组件层次）
- 复用哪些现有组件/composable
- 是否新增 store（理由）
- API 层如何组织（几个文件，是否有 mapper）
- 最大风险点是什么
- 开发顺序

---

## 16. 附录（可选）

可补充：

- 数据流图
- 页面草图 / 设计稿截图
- 枚举值/字段映射完整表
- 接口请求/响应示例（从 Swagger/Apifox 复制）
- 状态机草图