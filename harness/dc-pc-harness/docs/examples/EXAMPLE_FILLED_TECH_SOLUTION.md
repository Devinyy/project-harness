# EXAMPLE_FILLED_TECH_SOLUTION.md

> 说明：这是一个“已填充示例”，用于说明 `09_TECH_SOLUTION_TEMPLATE.md` 应该写到什么程度。
> 场景完全虚构，请替换为你项目的真实需求。

---
owner: Frontend Team
last_verified: 2026-04-21
status: example
purpose: 演示完整前端技术方案的写法与颗粒度。
related:
  - ../09_TECH_SOLUTION_TEMPLATE.md
  - ../10_TECH_SOLUTION_PLAYBOOK.md
---

# 前端技术方案

## 0. 元信息

- 需求名称：商家列表页新增批量启用 / 停用能力
- 需求 / 任务 ID：FE-EXAMPLE-001
- 方案作者：Frontend Team
- 评审人：Tech Lead / PM / QA
- 创建日期：2026-04-21
- 当前状态：approved
- 关联文档：
  - PRD：商家运营效率优化需求
  - 设计稿：商家列表页批量操作交互稿
  - API 文档：商家批量状态修改接口
  - 相关代码目录：`src/pages/merchant`, `src/features/merchant`, `src/services/merchant`

## 1. 背景与目标

当前商家列表页只支持逐条启用 / 停用，运营在处理批量审核通过后的商家时需要重复点击，效率低且易漏操作。

本次目标：

- 在商家列表页支持批量启用 / 停用
- 支持根据当前选中项状态自动禁用不合法操作
- 成功后刷新列表并保留当前筛选与分页
- 全流程遵守现有权限和操作确认规范

非目标：

- 本期不支持跨页全选
- 本期不新增导出能力
- 本期不重构现有商家列表页字段结构

## 2. 需求范围

- 影响页面：商家列表页
- 影响角色：拥有商家状态管理权限的运营角色
- 新增组件：`MerchantBatchActions`
- 修改组件：`MerchantTable`
- 新增 / 修改接口：批量修改商家状态接口
- 新增 / 修改埋点：批量启用、批量停用点击与成功埋点
- 新增 / 修改权限点：复用现有商家状态修改权限点

不在范围内：

- 商家详情页单条状态修改逻辑不改
- 审核流不改
- 列表筛选项不改

## 3. 用户流程与页面影响面

用户主流程：

1. 运营进入商家列表页
2. 通过筛选找到目标商家
3. 勾选多条记录
4. 点击“批量启用”或“批量停用”
5. 系统展示二次确认弹窗
6. 提交成功后 toast 提示并刷新当前列表
7. 保留筛选条件与分页位置

影响区域：

- 列表勾选列
- 批量操作工具栏
- 行状态标签
- 统一确认弹窗
- 商家 service
- 权限判断
- 埋点

## 4. 现状调研

可复用资产：

- 列表页骨架：现有 `MerchantListPage`
- 表格组件：`AppTable`
- 二次确认弹窗：`ConfirmActionModal`
- 权限组件：`PermissionGuard`
- 行状态标签：`MerchantStatusTag`
- 查询 hook：`useMerchantListQuery`

现状不足：

- 当前工具栏仅支持刷新和新建
- 未沉淀批量操作组件
- 单条状态修改逻辑位于行操作中，无法直接复用

## 5. 信息架构与路由设计

本需求不新增路由。

页面结构保持：

1. PageHeader
2. FilterArea
3. TableToolbar（新增批量操作区）
4. MerchantTable
5. Pagination

关键状态：

- 未选中：批量按钮禁用
- 选中全为启用中：仅“批量停用”可用
- 选中全为停用中：仅“批量启用”可用
- 混合状态：两个按钮都禁用，并提示“仅支持同状态批量操作”

## 6. UI 与组件方案

组件选型：

- 页面容器：复用现有 Page 容器
- 工具栏：新增 `MerchantBatchActions`
- 确认方式：Modal，不用 Drawer
- 成功反馈：toast
- 状态提示：沿用 `MerchantStatusTag`

复用与新增决策：

- 直接复用：表格、确认弹窗、权限判断、状态标签
- 扩展：`MerchantTable` 增加 `rowSelection`
- 新增：`MerchantBatchActions`

交互细节：

- 选择数量在工具栏展示
- 确认弹窗文案根据操作类型变化
- 提交中禁用按钮，防重复提交
- 成功后清空勾选并刷新列表
- 失败后保留勾选，方便重试

## 7. 数据流设计

数据流：

`MerchantListPage -> MerchantBatchActions -> merchant service -> refresh merchant list -> UI`

请求时机：

- 用户点击确认按钮后发起
- 成功后触发列表 query 重新请求
- 不引入全局 store，勾选状态保留在页面局部状态中

状态归属：

- 当前选中 ids：page local state
- 当前列表数据：query hook
- 当前筛选条件 / 分页：保持现有实现

## 8. API 与字段映射

接口：

- `POST /api/merchants/batch-status`

请求参数：

- `merchantIds: string[]`
- `targetStatus: ENABLED | DISABLED`

返回：

- `successCount`
- `failedIds`
- `message`

处理规则：

- `failedIds` 非空时提示“部分处理失败”，并建议刷新
- 完全成功时 toast 成功并刷新列表
- 权限错误时提示无权限，不清空勾选

## 9. 风险点与回滚方案

风险：

- 表格勾选逻辑与现有分页、刷新逻辑冲突
- 混合状态批量操作禁用规则实现错误
- 成功后刷新导致勾选状态残留

回滚：

- 批量操作工具栏可通过 Feature Flag 隐藏
- 若线上异常，可先关闭入口，保留现有单条操作能力

## 10. 开发拆分与工时预估

- Day 1：补 service、批量操作组件、表格勾选状态
- Day 2：补确认弹窗、成功失败处理、自测
- Day 3：回归权限、埋点、边界场景

## 11. 验收标准

- 支持批量启用 / 停用
- 禁止混合状态误操作
- 成功后刷新列表并清空勾选
- 失败时给出明确提示
- 不影响原单条操作逻辑
- 权限不正确时不可见或不可执行

## 12. 自测清单

- 仅选中启用中商家，批量停用成功
- 仅选中停用中商家，批量启用成功
- 混合状态时按钮禁用
- 选中后切页 / 刷新行为正确
- 无权限角色看不到批量操作
- 部分失败时提示正确
