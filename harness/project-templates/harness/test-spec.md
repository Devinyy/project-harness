---
owner: pending
created_at: {{DATE}}
checked_at: pending
status: template
purpose: 定义稳定、可重复的目标验收用例和覆盖边界
source: 已确认规则、接口契约、项目验证命令和运行环境
maintained_when: 需求规则、操作流程、风险范围或验证环境变化时
---

# Test specification / 验收用例定义

本文件只定义“应该如何验证”；实际执行结果、日志和截图保存在项目 `docs/` 证据资料中。通用验收角色和升级规则唯一引用项目根 `docs/harness/verification.md`，不在这里复制公共正文。

## 用例模板

```text
ID: CASE-<稳定编号>
目标规则: REQ-<编号>
关联模块: <module> | none
关联决策: ADR-<编号> | none
关联实现: IMPL-<编号> | none
关联交互: UX-<编号> | none
关联偏差: DEV-<编号> | none
关联验收: QA-<编号> | none
验收方式: self-check | independent-QA | user-acceptance
触发依据: <verification contract 条目；低影响自检写明原因>
前提: <环境、账号角色、数据、权限和版本条件>
操作:
  1. <可重复步骤>
  2. <可重复步骤>
预期: <可观察结果和错误/边界结果>
覆盖边界: <端、权限、数据、回归或未覆盖范围>
执行证据: <待执行时写 pending；执行后引用 docs/ 证据>
执行计划: planned | in-progress | blocked | done | cancelled
验收结果: pass | fail | blocked | unverified
创建时间: <实际创建时间，含时区>
核对时间: <实际核对时间，含时区；未执行写 pending>
```

用例 ID 不因目标改名而复用。验收方式字段记录本用例实际采用的角色；公共 QA 触发条件、独立角色、受阻、复验和升级规则唯一引用项目根 `docs/harness/verification.md`，本文件不复制那套公共规则。
