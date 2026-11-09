---
owner: pending
created_at: {{DATE}}
checked_at: pending
status: template
purpose: 记录架构与协作决策及其替代关系
source: 用户/团队批准的 ADR、方案评审和可追溯证据
maintained_when: 方案被批准、替代、撤回或影响面变化时
---

# ADR / 架构决策记录

一条决策一个稳定编号。没有已批准决策时保持 `proposed`，不要把模板内容当作项目选择。

## 决策记录

```text
ID: ADR-<稳定编号>
关联目标: REQ-<编号> | none
关联实现: IMPL-<编号> | none
来源: <用户/团队/评审记录引用>
创建时间: <实际创建时间，含时区>
核对时间: <实际核对时间，含时区；未复核写 pending>
决策状态: proposed | accepted | superseded | rejected
适用范围: <系统、跨端、前端领域或协作流程>
背景: <需要解决的问题和约束>
备选:
  - <方案 A + 取舍>
  - <方案 B + 取舍>
决策: <被批准的选择；未批准时保持 pending>
影响: <实现、接口、团队流程、验证和发布影响>
替代: <supersedes/superseded-by 的 ADR ID；没有写 none>
证据: <方案、代码、环境或验收证据路径>
未验证范围: <尚未核对的端、环境或调用方>
下一步: <需要补充的行动和责任角色>
```

决策解释“为什么”，不复制 `impl.md` 的当前实现。发生替代时保留旧记录并互相引用；不要删除历史 ADR 或用代码现状推定用户批准。
