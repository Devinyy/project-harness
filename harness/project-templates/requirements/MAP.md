---
owner: Harness Knowledge System
status: template
purpose: 需求目标、确认规则与模块追溯入口
source: 用户确认需求、PRD/任务单和项目范围记录
maintained_when: 需求确认、范围变化或模块入口变化时
---

# Requirements MAP

| 要回答的问题 | 入口 | 条件 |
| --- | --- | --- |
| 需求范围和排除项是什么？ | [overview.md](./overview.md) | 需求进入记录或范围变化时 |
| 哪些规则已由用户确认？ | [confirmed-rules.md](./confirmed-rules.md) | 只写有来源的确认，不把实现当确认 |
| 某条规则影响哪个模块？ | [modules/MAP.md](./modules/MAP.md) | 模块明确存在或显式实例化后 |
| 模块实现、用例和偏差在哪里？ | `requirements/modules/<module>.md` | 按模块名显式生成后 |

本域只维护用户目标一份；实现状态、验收结果和差距通过稳定 ID 引用 harness 与 docs 资料。没有确认来源时保持 `pending`，不创建业务事实。
