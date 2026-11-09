---
owner: Harness Knowledge System
status: template
purpose: 维护用户已确认的稳定规则与适用范围
source: 用户明确确认、PRD/任务单或批准的决策记录
maintained_when: 用户确认、撤回、替代或范围变化时
---

# Confirmed rules

规则编号稳定、不重排、不复用。确认规则只维护目标，不写实现已经完成的结论；目标与实现不一致时在 `{{ROOT}}harness/deviations.md` 记录偏差。

## 规则模板

```text
ID: RULE-<稳定编号>
需求: REQ-<编号>
确认状态: confirmed | pending | rejected | superseded
来源: <用户/PRD/任务/ADR 引用>
确认日期: <YYYY-MM-DD 或 pending>
目标行为: <可观察的目标>
适用范围: <端、角色、模块、数据或环境>
排除范围: <明确不包含的内容>
验收用例: CASE-<编号> | none
实现状态: not-started | partial | observed | not-found
验收结果: pass | fail | blocked | unverified
关联偏差: DEV-<编号> | none
下一步: <仍需确认、实现或验证的行动>
```

当前实现和验收结果只通过 ID/路径引用；不因实现存在就改写确认状态。
