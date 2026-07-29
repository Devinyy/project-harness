# 13_AGENT_POLICY.md

> 🧩 模版骨架：按项目真实约束细化，但必须保留 Allowed / Blocked / Ask First 三个顶层分组；不要把需确认事项误写成默认授权。

---
owner: Frontend Team
last_verified: <生成时填写>
status: template
purpose: AI agent 的显式操作权限边界
---

## Allowed

- 在用户明确范围内读取、搜索、诊断和修改普通业务代码，并运行仓库已有的检查命令。
- 复用现有页面、组件、composable、API/service 与 dcgj-ui；执行可恢复、仅影响本仓库的本地操作。
- 在不改变 business semantics 的前提下做最小实现；无法从代码或 active specs 取证时标记待确认。

## Blocked

- destructive 操作：针对仓库根、用户目录或未解析目标的递归删除，硬重置，强推，以及不可恢复的数据破坏。
- 将 token、密钥、完整提示词、完整 shell 命令、文件内容或环境变量值写入审计记录或未经授权对外披露；读取用户范围外明确承载密钥的文件。
- 绕过或关闭安全 Hook 和验证门禁。
- 引入非约定框架/UI 库、跨 app import、绕过数据层裸调接口，或在没有需求时重构公共基础设施。

## Ask First

- dependency 安装、升级、删除或 lockfile 的非必要重写。
- network egress，包括主动访问外部服务、上传内容或下载并执行代码。
- 修改 dangerous zone：基座、共享包、路由、认证、请求封装、权限、环境和构建配置。
- 无法确认 business semantics 时修改状态流转、权限判断、渠道分流、接口字段或持久化行为。
- external writes：发消息、创建/更新工单、PR、云文档、部署或改变任何仓库外系统状态。
