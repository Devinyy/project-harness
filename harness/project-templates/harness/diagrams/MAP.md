---
owner: Harness Knowledge System
status: template
purpose: 导航 Harness 资料结构和维护图示
source: 当前根 MAP、入口文件、project-templates/MANIFEST.tsv
maintained_when: 目录、域、生成接口或导航关系变化时
---

# Harness diagrams MAP

图示文件只表达 Harness 资料结构与导航，不表达不存在的业务系统、模块、API 或生产环境事实。

| 图示 | 用途 | 更新条件 |
| --- | --- | --- |
| `{{ROOT}}docs/harness/diagrams/harness-knowledge-system.mmd` | 当前根入口、领域模板、生成器和前端 specs 的关系 | 根 MAP、模板域或生成接口变化 |
| `{{ROOT}}docs/harness/diagrams/harness-navigation.mmd` | 按问题选择入口及三态/按需生成路径 | MAP 或初始化状态语义变化 |
| [maintenance.md](./maintenance.md) | 图示维护方法和证据边界 | 图示流程变化 |

生成到目标项目后，实际图示登记在项目 `docs/harness/diagrams/`；不存在的可选业务资料只用 code 路径和状态说明。
