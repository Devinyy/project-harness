# Project Harness 总 MAP

这是随 Harness 分发的静态工具导航，不承载某个业务项目的事实，也不会被初始化器改写。接入项目后的用户资料登记入口固定为项目根 `PROJECT_MAP.md`；先从它选择已实际生成的领域，再按条件加载资料。根规则见 [AGENTS.md](./AGENTS.md)，Claude 入口见 [CLAUDE.md](./CLAUDE.md)。

## 问题导航

| 要回答的问题 | 入口 | 条件 |
| --- | --- | --- |
| 用户要交付什么、目标是否已确认？ | 项目约定的 `docs/requirements/` 或 PRD/任务单 | 按需建立；没有确认目标时保持 `pending` |
| 全系统/跨端架构在哪里？ | 项目已有的系统/跨端架构文档；没有时按需建立 `docs/architecture/` | 先读系统边界和跨端约束，不用前端 specs 代替全系统事实 |
| 架构决策和 ADR 在哪里？ | 项目已有的 ADR；没有时按需建立 `docs/decisions/` | 保留历史决策并引用后续替代决策 |
| 前端领域架构在哪里？ | 项目 `docs/specs/02_ARCHITECTURE.md` | 初始化后按 specs 状态查阅，只记录前端实现事实 |
| 前端开发从哪里开始？ | 项目 `docs/specs/INDEX.md`、`00_PROJECT_FACTS.md` 与 [.claude/commands/](./.claude/commands/) | specs 为 `active` 时先读 facts + INDEX；已知任务可直达专项入口 |
| API 联调、接口契约和环境证据在哪里？ | 项目 `docs/specs/07_API_CONTRACTS.md` 与按需建立的 `docs/evidence/` | 只记录真实接口/环境证据；缺环境标记 `blocked` |
| 一次验收的 QA、CASE、环境和复验证据在哪里？ | 生成 docs domain 后的 `docs/acceptance-evidence.md` | 显式生成后使用；没有实际执行保持 `unverified`/`blocked` |
| 如何验收、复验并关闭偏差？ | [docs/harness/verification.md](./docs/harness/verification.md) 与项目验收证据 | 所有行为变更按风险决定独立 QA；不静默删除历史 |
| 发布、回滚和事故记录在哪里？ | 项目按需建立的 `docs/release/`、`docs/evidence/` 与危险区规则 | 只有任务或项目确有资料时建立，路径不存在时不伪造链接 |
| 接入项目后哪些资料域已生成？ | 项目根 `PROJECT_MAP.md` | 初始化器创建；只登记实际存在的 domain 与 `badcase/` |
| Harness 的边界、三态和授权是什么？ | [AGENTS.md](./AGENTS.md) 与 [CLAUDE.md](./CLAUDE.md) | 所有任务 |
| 如何记录目标、实现、决策和证据？ | [docs/harness/knowledge.md](./docs/harness/knowledge.md) | 需要新增或更新知识时 |
| 何时自检、独立 QA、复验或升级？ | [docs/harness/verification.md](./docs/harness/verification.md) | 所有需要验收的任务 |
| 如何初始化项目规格？ | [scripts/init-specs.sh](./scripts/init-specs.sh) 或 [/init-specs playbook](./.claude/commands/init-specs.md) | `missing` 执行脚手架；draft 继续填充；`active` 跳过 |
| 如何初始化项目资料域？ | `bash scripts/init-project-knowledge.sh --domain <domain>` | 生成 `PROJECT_MAP.md` 和实际选定的 domain；不覆盖用户资料 |
| 如何执行某类任务？ | [.claude/commands/](./.claude/commands/) 下的专项 playbook | 新页面、排障、重构、审查或技术方案 |
| 如何核对 Harness 包本身？ | [scripts/verify-harness.sh](./scripts/verify-harness.sh) 与 [scripts/doctor.sh](./scripts/doctor.sh) | 发布或修改 Harness 时 |
| 某个 flavor 的 specs 骨架是什么？ | [SCHEMA.md](./spec-templates/SCHEMA.md)、[PC INDEX](./spec-templates/pc-microapp/INDEX.md)、[uni-app INDEX](./spec-templates/miniprogram-uniapp/INDEX.md) | 接入项目或补模板时 |
| 可复用资料模板和机器清单在哪里？ | [project-templates/README.md](./project-templates/README.md) 与 [MANIFEST.tsv](./project-templates/MANIFEST.tsv) | 生成或维护需求/实现/证据资料时 |
| 当前 Harness 结构和导航图在哪里？ | [docs/harness/diagrams/MAP.md](./docs/harness/diagrams/MAP.md) | 根入口、模板域或生成接口变化时 |

## 资料边界

### Harness 本体（随包分发）

- 通用规则： [knowledge](./docs/harness/knowledge.md)、[verification](./docs/harness/verification.md)。
- 入口规则： [AGENTS](./AGENTS.md)、[Claude](./CLAUDE.md)、[Cursor](./.cursor/rules/project-harness.mdc)、[Windsurf](./.windsurfrules)。
- 可执行机制： `scripts/`、`.claude/hooks/`、`.codex/hooks/`、`.claude/commands/`。
- 前端模板： [spec-templates/SCHEMA.md](./spec-templates/SCHEMA.md) 与两个 flavor 目录；模板中的业务字段必须继续取证，不是 Harness 事实。

### 接入项目后的前端领域入口

初始化后，目标项目根目录会有 `docs/specs/INDEX.md`、`docs/specs/00_PROJECT_FACTS.md` 和按 flavor 生成的其他文档。它们是项目实现事实的入口；只有 `missing / draft / active` 语义允许的范围内才能使用，判断规则仍由根 [AGENTS.md](./AGENTS.md) 约束。

`docs/specs/INDEX.md` 只导航项目前端领域资料；`docs/specs/11_DANGEROUS_AREAS.md` 和 `docs/specs/13_AGENT_POLICY.md` 仍是危险区与授权的项目入口。Harness 本体不创建真实项目的 `docs/specs/`，也不把不存在的项目路径写成有效链接。

### 静态 MAP 与项目 PROJECT_MAP

- 本文件 `MAP.md` 是 Harness 分发包中的静态导航；它只链接随包提供的规则、模板和工具。
- 目标项目的 `PROJECT_MAP.md` 由显式初始化器在输出根创建，frontmatter 为 `status: draft`，标题为“项目资料登记”，只登记实际生成的 `harness/`、`requirements/`、`design/`、`docs/`、`experience/` 与 `badcase/` 路径。
- 已有 `PROJECT_MAP.md` 的正文由用户维护并保留；升级或重复初始化只去重/追加生成区块，不覆盖正文，不把分发 `MAP.md` 当作用户索引。

### 按需业务资料

用户目标、PRD、差距记录、ADR、API 联调、发布/回滚或运行证据按需放在目标项目约定的资料目录（例如 `docs/requirements/`、`docs/decisions/`、`docs/evidence/`、`docs/release/`），由项目自行确认路径并在本项目 MAP 中补入口。它们不是 `docs/specs/` 的实现事实；没有真实资料时不创建空文件、不伪造链接。目标与实现的记录格式见 [knowledge contract](./docs/harness/knowledge.md)。

### 可复用资料模板与显式生成

`project-templates/` 是模板源，不是业务事实库。它按 `harness`、`requirements`、`design`、`docs`、`experience` 五个 domain 提供结构，`badcase/` 是 experience 的可选案例路径；机器清单固定为三列 Tab 分隔的 [MANIFEST.tsv](./project-templates/MANIFEST.tsv)。模板本身保持 `status: template`，显式生成后才得到 `status: draft` 的目标项目资料；没有真实来源时不生成空模块或案例。

生成器由工具入口按需执行，调用方提供目标项目当前目录：

```text
bash scripts/init-project-knowledge.sh --domain harness
bash scripts/init-project-knowledge.sh --domain requirements --module <module>
bash scripts/init-project-knowledge.sh --domain design
bash scripts/init-project-knowledge.sh --domain docs
bash scripts/init-project-knowledge.sh --domain experience --case <case>
bash scripts/init-project-knowledge.sh --domain all --dry-run
```

初始化命令不迁移既有资料、不覆盖用户文件；`--module`/`--case` 只在显式提供安全标识时实例化。生成内容位于 `docs/specs/` 之外，并在 `PROJECT_MAP.md` 登记实际生成路径；前端 specs、token、授权和公共验收继续引用目标项目已有唯一来源。未生成的跨 domain 资料只以 code 路径和状态说明存在。

## 三态路由

- `missing`：运行 `bash scripts/init-specs.sh`（Claude 可用 `/init-specs`），再按 flavor 的 `_RULE.md` 从源码填充。
- `draft`：骨架、占位符或未复核状态仍在；draft 继续填充，不得当作项目事实，完成后人工复核。
- `active`：facts 存在、无占位符且文档均为 `active`；先读 facts 与项目 `INDEX.md`，其余按需查阅。

通用验收只在 [docs/harness/verification.md](./docs/harness/verification.md) 维护；flavor 与任务 playbook 只补充项目差异，不复制整套流程。
