---
owner: pending
created_at: {{DATE}}
checked_at: pending
status: template
purpose: 执行前的范围、来源、权限和验证准备记录
source: 任务单、项目规则、授权记录和可复跑命令
maintained_when: 任务边界、授权或验证入口变化时
---

# Preflight

- 创建时间（UTC）：{{DATE}}
- 核对时间（UTC）：`<实际核对时间；未核对写 pending>`
- 任务/需求 ID：`<REQ-...>`
- 执行范围：`<写明目标与排除项>`
- 事实来源：`<源码、运行证据、用户确认或文档路径>`
- 授权边界：`<按项目政策记录 Allowed / Ask First / Blocked>`
- 预计产物：`<文件或可验证行为>`
- 执行计划：`<planned | in-progress | blocked | done | cancelled>`
- 验证命令与前置条件：`<命令/环境/账号，未确认则写 unverified>`
- 关联用例：`<CASE-...>`

## 前端引用

若任务涉及前端，引用项目根的 `docs/specs/06_UI_COMPONENT_GUIDE.md`、`docs/token-specs/` 与 `docs/harness/verification.md`；不要在此复制组件、token 或公共验收规则。

## 结果边界

本记录只说明执行前已核对什么，不代表实现、验收或生产状态已成立。实际结果另留在对应的实现、用例和证据记录中。
