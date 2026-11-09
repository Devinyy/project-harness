---
owner: pending
created_at: {{DATE}}
checked_at: pending
status: template
purpose: 记录需求范围、目标、排除项和确认来源
source: 用户、已确认 PRD、任务单或决策记录
maintained_when: 新需求进入、范围确认或排除项变化时
---

# Requirements overview

## 需求元数据

```text
ID: REQ-<稳定编号>
标题: <用户确认的目标标题>
来源: <用户/PRD/任务单/决策引用>
确认状态: confirmed | pending | rejected | superseded
确认日期: <YYYY-MM-DD 或 pending>
适用范围: <系统、端、模块、角色或环境>
排除范围: <明确不在本次范围的能力>
关联规则: RULE-<编号> | none
关联模块: <module> | none
```

## 目标行为

<填写：只写用户确认的结果和范围；没有来源时保持 pending，不从按钮、旧代码或模板示例推定目标。>

## 维护说明

确认规则在 [confirmed-rules.md](./confirmed-rules.md) 维护；模块用 `requirements/modules/<module>.md` 按需建立。当前实现不要复制到需求文档，引用 `{{ROOT}}harness/impl.md` 与项目 `docs/specs/` code 路径即可。
