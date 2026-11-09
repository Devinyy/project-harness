---
owner: Harness Knowledge System
status: template
purpose: 可选的经验、预检、复盘和 badcase 导航
source: 实际执行记录、用户反馈、运行证据和项目公共规则
maintained_when: 经验记录新增、复盘结论变化或 badcase 关闭时
---

# Experience MAP

本域是可选资料，不是业务事实的默认来源。只在有真实执行记录、失败证据或复盘结论时显式生成；没有来源时保持空域，不创建占位案例。

| 要回答的问题 | 入口 | 条件 |
| --- | --- | --- |
| 如何做一次执行前检查？ | [aibrain/preflight.md](./aibrain/preflight.md) | 需要可重复的任务前核对时按需生成 |
| 一次执行得到什么经验？ | [aibrain/retrospective.md](./aibrain/retrospective.md) | 有实际结果、证据和后续动作时按需生成 |
| 键盘/焦点事件如何复盘？ | [aibrain/keyboard-events.md](./aibrain/keyboard-events.md) | 目标项目确有此类交互与证据时按需生成 |
| 已知失败如何追踪？ | `badcase/MAP.md` 与 `badcase/<case>.md` | 仅在显式提供案例名并有证据时生成 |

前端规范、token、UI 状态和公共验收继续引用项目根 `docs/specs/`、`docs/token-specs/` 与 `docs/harness/verification.md`；本域不复制这些正文。未生成的跨域资料只写项目根 code 路径和状态，不建立不可解析链接。
