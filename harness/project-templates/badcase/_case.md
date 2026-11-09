---
owner: pending
status: template
purpose: 单个失败案例的可追踪记录模板
source: 实际失败输出、用户反馈、QA 记录和修复/复验证据
maintained_when: 案例发现、修复、复验或关闭时
case: {{CASE}}
---

# Badcase: {{CASE}}

- 案例 ID：`<CASE-...>`
- 需求/模块 ID：`<REQ-...>` / `<模块 ID 或 none>`
- 发现日期（UTC）：{{DATE}}
- 当前状态：`<pending | partial | observed | not-found | blocked | unverified>`
- 发现角色：`<执行者/QA/用户>`

## 复现与影响

- 前置条件：`<实际环境和数据；未确认写 unverified>`
- 复现步骤：`<可重复步骤>`
- 预期：`<目标或确认规则 ID>`
- 实际：`<证据支持的结果>`
- 影响范围：`<受影响模块/端/用户>`
- 当前证据：`<命令输出、截图、日志或平台记录路径>`

## 闭环

- 偏差 ID：`<DEV-...>`
- 修复责任角色：`<角色>`
- 下一步：`<动作和负责人>`
- 修复证据：`<路径或 pending>`
- 独立复验角色：`<原实现者之外的角色，或 pending>`
- 复验/关闭证据：`<路径或 pending>`

不要把本案例当作需求或实现的唯一来源；需求、实现、验收状态通过稳定 ID 互相引用。前端规范/token/公共验收分别引用项目根 `docs/specs/`、`docs/token-specs/` 和 `docs/harness/verification.md`，不在案例中复制正文。
