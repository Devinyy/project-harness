---
owner: Harness Knowledge System
status: template
purpose: 环境、接口、后端、发布和回滚证据入口
source: 可重跑命令、服务/平台输出、仓库提交和人工核对
maintained_when: 联调、环境、后端证据、发布或回滚变化时
---

# Docs / evidence MAP

| 要回答的问题 | 入口 | 条件 |
| --- | --- | --- |
| 当前在哪个仓库、提交和环境核对？ | [environment.md](./environment.md) | 任何依赖环境的验证 |
| API 联调结果和前后端契约是什么？ | [api-integration.md](./api-integration.md) | 接口联调或契约变化 |
| 后端/跨仓库证据在哪里？ | [backend-evidence.md](./backend-evidence.md) | 有后端、网关、服务或跨仓库证据时 |
| 发布、回滚和线上状态如何核对？ | [release-evidence.md](./release-evidence.md) | 发布/回滚任务或平台状态变化 |

本域记录证据，不把本地源码、构建成功或平台部署成功推定为生产业务通过。没有实际证据时保持 `unverified`；因环境、权限或依赖无法执行时保持 `blocked`。
