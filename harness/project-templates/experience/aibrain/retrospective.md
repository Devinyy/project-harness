---
owner: pending
status: template
purpose: 有证据的执行复盘与后续动作
source: 实际命令输出、运行观察、QA 结果和用户反馈
maintained_when: 任务结束、偏差修复或新证据产生时
---

# Retrospective

- 记录日期（UTC）：{{DATE}}
- 需求/模块 ID：`<REQ-...>` / `<模块 ID 或 none>`
- 关联用例：`<CASE-...>`
- 执行者与独立 QA：`<角色；自检不计独立 QA>`
- 结果状态：`<pending | partial | observed | not-found | blocked | unverified>`

## 事实与证据

- 实际完成：`<只写有来源的事实>`
- 未完成或未验证：`<明确范围>`
- 证据路径：`<docs/...、命令输出或平台记录>`
- 与目标/规范的偏差：`<DEV-... 或 none>`

## 改进动作

- 保留做法：`<依据和原因>`
- 需要调整：`<具体下一步与负责人>`
- 修复证据：`<路径或 pending>`
- 复验/关闭证据：`<路径或 pending>`

复盘不替代需求、实现或验收记录；历史失败和关闭证据追加保留，不静默删除。前端事实继续引用项目根 `docs/specs/`，通用验收规则引用 `docs/harness/verification.md`。
