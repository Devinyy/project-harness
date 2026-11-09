---
owner: pending
created_at: {{DATE}}
checked_at: pending
status: template
purpose: 场景级实现与验收入口
source: 现有 .claude/commands、docs/harness/verification.md 和项目任务流
maintained_when: 场景入口、专项 playbook 或验收来源变化时
---

# Harness 场景 MAP

| 场景 | 入口 | 条件 |
| --- | --- | --- |
| 开发、修复、重构 | [implement.md](./implement.md) | 任何实现变更 |
| 自检、独立 QA、用户验收 | [verify.md](./verify.md) | 先按风险判定验收方式 |
| 任务专项步骤 | 项目根 `.claude/commands/<name>.md` | 已知任务可直达；不复制正文 |
| 通用验收规则 | 项目根 `docs/harness/verification.md` | 唯一公共来源 |

本域只连接场景，不记录具体业务字段或验收结果。实施和验收结束后，按 harness 根域的模块、用例、偏差和证据入口更新引用。
