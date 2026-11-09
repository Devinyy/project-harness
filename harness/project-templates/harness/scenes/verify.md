---
owner: pending
created_at: {{DATE}}
checked_at: pending
status: template
purpose: 连接自检、独立 QA 和用户业务验收
source: 项目根 docs/harness/verification.md
maintained_when: 公共验收规则变化时，仅更新引用和项目差异
---

# Verify scene / 验收流程

本文件不复制触发条件、角色定义或升级规则；唯一公共验收规则是项目根 `docs/harness/verification.md`。本场景只提供资料连接：

1. 引用目标 ID、改动范围、实现状态和风险判定。
2. 由实现者完成自检，保存命令/操作、环境、实际结果和未验证范围。
3. 按项目根 `docs/harness/verification.md` 判定验收方式，并在 acceptance evidence 中记录角色、结果或阻塞输入。
4. 技术结果与用户业务验收分开记录；仅在任务需要或存在业务决策时安排用户验收。

前端视觉、token、权限和危险区的事实继续引用项目现有 `docs/specs/`，不在经验或用例模板中复制。
