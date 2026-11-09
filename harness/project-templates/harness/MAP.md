---
owner: pending
created_at: {{DATE}}
checked_at: pending
status: template
purpose: Harness 资料域的导航与维护入口
source: 项目已有入口、源码和经确认的协作规则
maintained_when: 新增/移动 harness 资料或改变追溯关系时
---

# Harness 资料域 MAP

本域只记录跨领域的协作与技术资料，不承载具体业务事实。先按问题选择唯一入口，再按需读取段落。

| 要回答的问题 | 入口 | 维护时机 |
| --- | --- | --- |
| 为什么采用某个架构决策？ | [adr.md](./adr.md) | 决策新增、替代或失效时 |
| 当前系统如何实现？ | [impl.md](./impl.md) 与项目 `docs/specs/` | 实现、配置或运行证据变化时 |
| 术语如何统一、如何改名？ | [naming.md](./naming.md) | 跨模块命名或术语变更时 |
| 如何定义可重复的验收用例？ | [test-spec.md](./test-spec.md) | 目标规则或覆盖边界变化时 |
| 目标与现状的差距如何闭环？ | [deviations.md](./deviations.md) | 发现、修复或关闭偏差时 |
| 开发和验收按什么顺序执行？ | [scenes/MAP.md](./scenes/MAP.md) | 场景入口或流程来源变化时 |
| 当前资料包如何维护和验证？ | [diagrams/MAP.md](./diagrams/MAP.md) | 导航/结构图变化时 |

目标项目的需求、设计、环境与发布资料分别由根 MAP 的对应 domain 入口维护。若相关 domain 尚未生成，使用项目根 code 路径标记“按需生成”，不要创建空业务文件。

追溯方向固定为：需求 ID → 模块 → 实现事实 → 用例 ID → 偏差 ID → 环境/接口/发布证据。前端实现事实引用现有 `docs/specs/`，通用验收引用项目根 `docs/harness/verification.md`。
