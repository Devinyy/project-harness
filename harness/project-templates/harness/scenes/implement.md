---
owner: pending
created_at: {{DATE}}
checked_at: pending
status: template
purpose: 规定从目标到实现记录的场景步骤
source: 项目根 .claude/commands 与现有前端 specs
maintained_when: 实现流程、专项 playbook 或资料记录字段变化时
---

# Implement scene / 实现流程

按以下顺序执行，普通问题在当前执行角色内完成修复和复验：

1. **目标**：引用稳定需求 ID，确认用户目标、排除范围和用户确认状态。
2. **范围**：定位模块、公共能力、接口、权限、数据和运行环境影响；读取项目 `docs/specs/INDEX.md`（仅在状态允许时）及相关危险区规则。
3. **实现**：复用现有代码和组件；前端专项步骤引用项目根 `.claude/commands/new-page.md`、`debug.md`、`refactor.md` 或 `tech-solution.md`，不在此复制。
4. **自检**：运行与风险匹配的命令/操作，记录改动文件、环境、结果和未验证范围。
5. **验收连接**：按项目根 `docs/harness/verification.md` 选择验收方式，并记录实际结果或阻塞输入。
6. **记录更新**：同步 module、impl、用例、偏差和 docs 证据；目标、实现和验收结果分开维护。

通用 QA 判断、复验和升级边界唯一引用项目根 `docs/harness/verification.md`。
