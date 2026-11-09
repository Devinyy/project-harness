---
owner: Harness Knowledge System
status: current
purpose: 当前 Harness 结构与导航图示入口
source: 根 MAP、AGENTS、knowledge/verification 契约、project-templates/MANIFEST.tsv
updated: 2026-11-09
maintained_when: 根入口、模板域、生成接口或三态路由变化时
---

# Harness diagrams MAP

这些图只表达本仓库能核对的 Harness 结构、资料域和导航关系，不表达具体业务系统、模块、API 或生产状态。

| 图示 | 用途 | 来源 |
| --- | --- | --- |
| [harness-knowledge-system.mmd](./harness-knowledge-system.mmd) | 根入口、模板域、显式初始化接口、目标项目资料和引用关系 | `MAP.md`、`project-templates/MANIFEST.tsv`、`docs/harness/knowledge.md` |
| [harness-navigation.mmd](./harness-navigation.mmd) | 按问题路由到系统架构/ADR、前端、联调证据、验收和发布，以及 specs 三态 | `MAP.md`、`AGENTS.md`、`docs/harness/verification.md` |

图示是导航辅助，不替代源文档或验收证据。未生成的业务 domain、模块、案例和环境状态继续用目标项目 code 路径及 `pending`/`unverified` 表达。
