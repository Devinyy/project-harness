# 08_TASK_PLAYBOOKS.md

> 🧩 模版骨架（A 精炼版）：保留结构，正文按真实代码填充；拿不准标 `// TODO: 待确认`，禁止编造。

---
owner: pending
created_at: <生成时填写>
checked_at: <实际复核时间或 pending>
status: template
purpose: 常见任务的标准步骤
---

本文件只补 uni-app flavor 的差异和实现取证；通用知识使用 [knowledge contract](../../docs/harness/knowledge.md)，通用验收（含独立 QA、受阻和增量复验）使用 [verification contract](../../docs/harness/verification.md)，不在此复制正文。

| 任务 | 专项流程来源 | 需要补的 flavor 证据 |
| --- | --- | --- |
| 新增页面 | [.claude/commands/new-page.md](../../.claude/commands/new-page.md) | pages.json、端差异、组件和页面类型 |
| 修复 bug | [.claude/commands/debug.md](../../.claude/commands/debug.md) | 根因、端影响和回归命令 |
| 重构 | [.claude/commands/refactor.md](../../.claude/commands/refactor.md) | composable/组件边界和行为不变证据 |
| 接口接入 | [SCHEMA.md](../../spec-templates/SCHEMA.md) 与项目 API 约定 | DTO、错误码和请求封装 |
| 新增组件 | [.claude/commands/new-page.md](../../.claude/commands/new-page.md) | uview-plus/项目组件调用和多端状态 |

## 新增页面
<填写：依据真实代码/配置提炼>

## 修复 bug
<填写：依据真实代码/配置提炼>

## 重构
<填写：依据真实代码/配置提炼>

## 接口接入
<填写：依据真实代码/配置提炼>

## 新增组件
<填写：依据真实代码/配置提炼>

每项任务完成后按 [verification contract](../../docs/harness/verification.md) 留下实现状态、命令/环境证据、验收结果和未验证范围。

