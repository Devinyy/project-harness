---
owner: pending
created_at: {{DATE}}
checked_at: pending
status: template
purpose: 规定 Mermaid 图示的维护与证据边界
source: MAP、入口文件、MANIFEST.tsv 和初始化器接口
maintained_when: 资料域或生成行为变化时
---

# Diagram maintenance / 图示维护

- 图示只从当前仓库可核对的 MAP、入口、模板清单和生成器接口提取；不从业务猜测补系统架构。
- 节点代表真实存在的入口或明确的按需路径；可选模块、案例、需求或生产环境用 code 路径，不绘成已存在的事实。
- 更新 MAP、MANIFEST.tsv、初始化器接口或 domain 依赖后，同步 `docs/harness/diagrams/` 并核对 Mermaid 语法和本地链接。
- 图示中不写 token 值、权限结果、业务字段、API 响应或生产状态；这些内容留在项目已有 specs 或 evidence 文件中。
- 每次更新记录来源、日期、分支/提交和未验证范围；图示不是验收证据本身。
