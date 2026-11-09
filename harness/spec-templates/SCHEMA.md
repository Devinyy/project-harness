# docs/specs 生成 Schema（通用，两类项目共用）

`/init-specs`（或 `scripts/init-specs.sh` + agent 填充）据此 + 对应 flavor 规则生成 `docs/specs/`。实现事实**必须从真实代码、配置或运行证据确认**；用户目标、团队规范、已批准决策和验收证据各自引用其权威来源，拿不准写 `// TODO: 待确认`，禁止编造。

这是前端领域的实现事实 Schema，不是业务需求或 Harness 通用规则的副本。总导航见 [MAP.md](../MAP.md)；目标、实现、规范、决策和证据的记录方法见 [docs/harness/knowledge.md](../docs/harness/knowledge.md)，通用验收见 [docs/harness/verification.md](../docs/harness/verification.md)。

## 事实分层

- **目标**：用户确认的范围和结果，用稳定需求编号记录在项目约定的需求资料中；不要把未确认目标填成 `docs/specs/` 的实现事实。
- **实现**：源码、配置、脚本和真实运行行为，填入本 Schema 对应的 `docs/specs/` 文档，并保留文件/命令/提交引用。
- **规范、决策、证据**：分别引用根入口、专项 playbook、已批准决策和可重跑证据；不在每份 flavor 文档复制通用正文。
- **状态**：用户确认状态、实现状态和验收结果独立记录。`status: active` 只表示实现事实已人工复核，不表示用户目标已验收。

## 必产文件

| 文件 | 内容要点 |
|------|----------|
| `INDEX.md` | 前端领域索引 + 使用纪律（用 head/grep，不 cat 全文；以真实代码为准）|
| `00_PROJECT_FACTS.md` | 项目当前实现的技术栈/UI 库/命令/目录/认证/API/禁止项；目标需求另按知识契约记录 |
| `02_ARCHITECTURE.md` | 目录结构、模块/子应用/分包、端口、路由组织、构建产物、外部依赖；**顶部含 harness 固定的「MVVM 通用分层模型」基线（保留不改，项目只补特例）** |
| `03_BUSINESS_DOMAIN.md` | 业务实体、状态流转、术语、权限/角色 |
| `04_CODING_STANDARDS.md` | 命名、类型、样式、错误处理、提交规范 |
| `05_COMPONENT_PATTERNS.md` | 组件拆分与复用、props/事件、状态选择；**「拆分原则」是 harness 固定基线（可判定触发条件 + 页面只做编排，保留不改）** |
| `06_UI_COMPONENT_GUIDE.md` | UI 库选型用法、图标/图片素材规则；PC 含 Figma/截图页面类型路由与视觉验收口径 |
| `07_API_CONTRACTS.md` | 请求/响应结构、错误码、接入步骤、DTO→VM |
| `08_TASK_PLAYBOOKS.md` | flavor 差异和专项入口；通用验收步骤引用 `docs/harness/verification.md` |
| `09_TECH_SOLUTION_TEMPLATE.md` / `10_TECH_SOLUTION_PLAYBOOK.md` | 技术方案模板与落地流程 |
| `11_DANGEROUS_AREAS.md` | 风险分级 + 危险区清单（路径+为什么危险+改动前必做+红线）|
| `12_TROUBLESHOOTING.md` | 已知问题与解法、调试入口 |
| `13_AGENT_POLICY.md` | agent 显式权限边界；只使用 `Allowed` / `Blocked` / `Ask First` 三个顶层分组，覆盖破坏性操作、依赖、外网、危险区、业务语义与外部写入 |
| `dangerous-zones.txt` | **机器可读**危险区路径清单，一行一个子串，`#` 注释；hooks 读取 |
| `verify.cmd` | **机器可读 fast profile**；一行一个命令、支持 `#` 注释；Stop hook 按顺序执行，`init-specs.sh` 优先写入真实 typecheck/validate 脚本，人工核对（如 monorepo filter）|
| `verify.full.cmd` | 可选的 **full profile** 增量命令；fast 通过后按顺序执行；只记录真实存在的 lint/build/test/smoke 脚本，不可编造 |
| 目录级 `AGENTS.md` | 在 flavor 列出的关键目录下生成局部约束 |

PC 的 `dcgj-components/COMPONENT_INDEX.md` 必须从实际锁定版本、组件库导出入口与项目真实调用取证。`examples/` 只允许从真实页面提炼；有设计输入时按列表、新建/编辑、详情分类，并明确示例不是字段、尺寸或操作的事实来源。

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

## verification profile 格式
- `verify.cmd` 是 fast profile，Stop hook 默认运行。
- `verify.full.cmd` 只放 fast 之外的深度检查；`bash scripts/run-verification-profile.sh full` 会先 fast、再 full。
- 两个文件均一行一个 shell 命令，忽略空行和以 `#` 开头的行，遇首个失败停止。
- 不同项目不要求具备相同脚本；不存在的检查写注释说明缺失，不得推断 `pnpm test` 等命令。

## 纪律
篇幅克制；路径/端口/字段/命令一律取证；flavor 给的是典型形态，真实值以当前仓库为准。
`02_ARCHITECTURE` 的「通用分层模型」与 `05_COMPONENT_PATTERNS` 的「拆分原则」是团队固定基线，**填充时保留不改**，只在其下补项目特例。

`03_BUSINESS_DOMAIN` 必须把用户确认的目标与当前实现事实分节；`08_TASK_PLAYBOOKS` 只写 flavor/项目差异并链接专项命令，不复制通用验收流程。填充完成后仍需人工复核，再将文档状态改为 `active`。
