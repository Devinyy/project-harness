# docs/specs 生成 Schema（通用，两类项目共用）

`/init-specs`（或 `scripts/init-specs.sh` + agent 填充）据此 + 对应 flavor 规则生成 `docs/specs/`。所有内容**必须从真实代码确认**，拿不准写 `// TODO: 待确认`，禁止编造。

## 必产文件

| 文件 | 内容要点 |
|------|----------|
| `INDEX.md` | 文档索引 + 使用纪律（用 head/grep，不 cat 全文；以真实代码为准）|
| `00_PROJECT_FACTS.md` | 项目名/技术栈/UI 库/包管理器/源码根/别名/启动·构建·类型检查·lint 命令/认证(token key)/API 基址/目录归属/项目专属禁止项 |
| `02_ARCHITECTURE.md` | 目录结构、模块/子应用/分包、端口、路由组织、构建产物、外部依赖 |
| `03_BUSINESS_DOMAIN.md` | 业务实体、状态流转、术语、权限/角色 |
| `04_CODING_STANDARDS.md` | 命名、类型、样式、错误处理、提交规范 |
| `05_COMPONENT_PATTERNS.md` | 组件拆分与复用、props/事件、状态选择 |
| `06_UI_COMPONENT_GUIDE.md` | UI 库选型用法、图标/图片素材规则 |
| `07_API_CONTRACTS.md` | 请求/响应结构、错误码、接入步骤、DTO→VM |
| `08_TASK_PLAYBOOKS.md` | 常见任务标准步骤 |
| `09_TECH_SOLUTION_TEMPLATE.md` / `10_TECH_SOLUTION_PLAYBOOK.md` | 技术方案模板与落地流程 |
| `11_DANGEROUS_AREAS.md` | 风险分级 + 危险区清单（路径+为什么危险+改动前必做+红线）|
| `12_TROUBLESHOOTING.md` | 已知问题与解法、调试入口 |
| `dangerous-zones.txt` | **机器可读**危险区路径清单，一行一个子串，`#` 注释；hooks 读取 |
| 目录级 `AGENTS.md` | 在 flavor 列出的关键目录下生成局部约束 |

## 文档头部（每份 md）

```
---
owner: Frontend Team
last_verified: <生成日期>
status: draft        # 人工复核后改 active
purpose: <一句话>
---
```

## dangerous-zones.txt 格式
一行一个**子串**（hook 用 grep 匹配文件路径），不要写正则；覆盖 11 中所有 P0/P1 路径。

## 纪律
篇幅克制；路径/端口/字段/命令一律取证；flavor 给的是典型形态，真实值以当前仓库为准。
