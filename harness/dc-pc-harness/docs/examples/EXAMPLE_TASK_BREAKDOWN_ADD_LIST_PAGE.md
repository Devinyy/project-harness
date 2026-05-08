# EXAMPLE_TASK_BREAKDOWN_ADD_LIST_PAGE.md

> 说明：这是 `08_TASK_PLAYBOOKS.md` 中“新增列表页”打法的一个简化示例。

---
owner: Frontend Team
last_verified: 2026-04-21
status: example
purpose: 演示 AI 或开发者在新增列表页前如何拆解任务、盘点风险与自测点。
related:
  - ../08_TASK_PLAYBOOKS.md
  - ../05_COMPONENT_PATTERNS.md
  - ../06_UI_COMPONENT_GUIDE.md
---

## 任务目标

新增“活动列表页”，支持：

- 关键词搜索
- 状态筛选
- 创建时间筛选
- 列表分页
- 行内查看详情
- 单条启用 / 停用操作

## 参考文档

- `02_ARCHITECTURE.md`
- `05_COMPONENT_PATTERNS.md`
- `06_UI_COMPONENT_GUIDE.md`
- `07_API_CONTRACTS.md`
- `11_DANGEROUS_AREAS.md`

## 复用点

- 页面骨架：复用现有列表页布局
- 筛选组件：复用 `SearchFilterBar` 风格
- 表格组件：复用 `AppTable`
- 状态标签：复用通用 `StatusTag`
- 确认弹窗：复用 `ConfirmActionModal`
- 请求模式：复用 query hook + service 模式

## 改动点

- 新增 `pages/campaign/ListPage`
- 新增 `features/campaign/CampaignFilter`
- 新增 `features/campaign/CampaignTable`
- 新增 `features/campaign/useCampaignColumns`
- 新增 `services/campaign/*`
- 新增路由和菜单配置
- 新增权限点接入

## 风险点

- 状态筛选与状态标签映射不一致
- 启用 / 停用操作与权限判断耦合
- 列表返回详情后上下文丢失
- 列表 query 参数与 URL 同步产生冲突

## 建议开发顺序

1. 先补路由与页面骨架
2. 补 service 与数据类型
3. 补筛选组件与 query state
4. 补表格列与行操作
5. 补详情跳转与上下文保留
6. 补权限、空态、loading、错误态
7. 自测并更新 docs

## 自测点

- 首屏正常加载
- 筛选条件生效
- 切页后参数正确
- 查看详情后返回列表，筛选条件仍保留
- 无权限角色按钮隐藏或禁用
- 启用 / 停用成功后列表刷新
- 空态、异常态和 loading 表现正确
