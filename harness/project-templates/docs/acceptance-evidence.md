---
owner: pending
created_at: {{DATE}}
checked_at: pending
status: template
purpose: 记录与需求、用例、实现和发布可追溯的验收证据
source: 项目根 docs/harness/verification.md、实际 QA 操作和运行环境证据
maintained_when: 验收执行、失败修复、复验或发布关联变化时
---

# Acceptance evidence / 验收证据

本文件记录一次实际验收，不复制公共 QA 触发和升级规则。角色、触发依据和受阻处理唯一引用项目根 `docs/harness/verification.md`。

```text
ID: QA-<稳定编号>
需求/目标: REQ-<编号> | none
用例: CASE-<编号> | none
实现: IMPL-<编号> | none
交互/设计: UX-<编号> | none
决策: ADR-<编号> | none
验收方式: self-check | independent-QA | user-acceptance
触发依据: <verification contract 条目；低影响自检写明原因>
实现者: <角色；未确认写 pending>
独立验收者: <原实现者之外的角色；不需要时写 none，需要但未安排写 pending>
环境/设备/账号: <实际环境、视口、设备和最小必要角色；不写秘密>
提交/构建: <commit、构建号或工作区标识>
预期结果: <引用 CASE 预期，不复制目标正文>
实际结果: <实际观察到的结果>
证据: <命令、日志、截图、平台输出或运行路径>
验收结果: pass | fail | blocked | unverified
失败原因: <失败或 blocked 的可追溯原因；通过写 none>
修复引用: <DEV-<编号>、提交或文件；无修复写 none>
复验结果: <原验收者的增量复验、证据路径或 pending>
未覆盖范围: <端、权限、数据、环境或用户验收未覆盖项>
阻塞输入: <环境、权限、账号或决策；无阻塞写 none>
发布关联: RELEASE-<编号> | none
创建时间: <实际创建时间，含时区>
核对时间: <实际核对时间，含时区；不要用生成日期替代>
```

发布记录应引用本文件的 `QA-...` 与对应 `CASE-...`；没有实际执行证据时保持 `unverified` 或 `blocked`，不得把模板生成或本地构建写成验收通过。

字段与验收方式必须相互一致：`independent-QA` 的独立验收者不得是实现者；尚未安排或无法执行的必填项写 `pending`/`blocked` 并保留复验入口，`none` 只用于明确不适用的关联。`self-check` 和 `user-acceptance` 也必须记录实际角色、环境、预期/实际结果和证据，不以空白代替未执行。
