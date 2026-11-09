# Harness 知识记录契约

本文件规定“什么算知识、谁是权威、如何记录状态”。它不替代目标项目的 `docs/specs/`，也不为 Harness 生成业务资料；随包根 `MAP.md` 是静态工具导航，目标项目的用户资料登记由根 `PROJECT_MAP.md` 承担；总入口见 [MAP.md](../../MAP.md)。

## 事实类型与权威范围

每条记录先标明类型。目标、当前实现、团队规范、决策和环境证据不得混写，也不能用一种类型的内容覆盖另一种类型。

| 类型 | 记录什么 | 权威来源 |
| --- | --- | --- |
| 目标（Goal） | 用户确认的结果、范围、稳定需求编号（如 `REQ-xxx`） | 用户/已确认 PRD/任务单 |
| 实现（Implementation） | 当前代码、配置、脚本、路由、接口和真实运行行为 | 源码、配置、命令输出、运行环境 |
| 团队规范（Convention） | Harness、项目入口和目录级约束 | `AGENTS.md`、playbook、模板和已批准规则 |
| 决策（Decision） | 已选择的方案、取舍、影响面和待复核点 | 用户或团队明确批准的决策记录 |
| 环境证据（Evidence） | 命令、测试、截图、版本、环境和观察时间 | 可重跑命令或保存的原始证据 |

## 生命周期状态注册表

`status` 只在 frontmatter 中表示资料成熟度；记录正文必须使用有名字的维度字段，不能用一个“状态”同时表示目标确认、实现、计划、证据或偏差。各维度允许值集中如下：

| 维度 | 正文字段 | 允许值 | 说明 |
| --- | --- | --- | --- |
| 成熟度（maturity） | frontmatter `status` | `template` / `draft` / `active` | 模板源、未复核草稿、已人工复核的实现资料；`active` 不等于用户验收通过 |
| 目标确认（confirmation） | `确认状态` / `用户确认状态` | `confirmed` / `pending` / `rejected` / `superseded` | 只表达用户目标是否成立；被替代的目标保留历史引用 |
| 实现（implementation） | `实现状态` | `not-started` / `partial` / `observed` / `not-found` | 只表达源码、配置或运行事实 |
| 规范/术语（convention） | `规范状态` / `术语状态` | `current` / `pending` / `retired` | 只表达团队规范或稳定术语是否仍适用 |
| 决策（decision） | `决策状态` | `proposed` / `accepted` / `superseded` / `rejected` | 只表达 ADR 或批准方案的生命周期 |
| 执行计划（plan） | `执行计划` / `计划状态` | `planned` / `in-progress` / `blocked` / `done` / `cancelled` | 与实际证据结果分开 |
| 证据（evidence） | `验收结果` / `证据结果` | `pass` / `fail` / `blocked` / `unverified` | 只由实际命令、运行、QA 或用户证据支持 |
| 偏差（deviation） | `偏差状态` | `open` / `in-fix` / `recheck` / `closed` / `blocked` | 关闭必须追加修复和复验证据，不删除历史 |
| QA 方式（qa mode） | `验收方式` | `self-check` / `independent-QA` / `user-acceptance` | 角色选择引用 verification contract，不在资料模板复制触发条件 |

项目资料的 owner 默认写 `pending`，待真实责任角色认领后再填。`created_at`/`创建时间` 记录建立时间，`checked_at`/`核对时间` 记录实际核对时间并保留时区；模板生成日期只能作为创建日期，不能冒充核对日期。公共 token 可以没有 `REQ` 关联，其他关联按实际任务需要填写 `none`，不为完整链路伪造空记录。

目标项目的 `docs/specs/` 是实现事实的索引和记录入口，不是对新鲜证据的替代：源码、配置或运行证据更新时，以可追溯的最新证据为准，并在记录中标出文档与证据的冲突。Harness 只提供模板和记录方法。外部需求草稿可以放在项目的需求目录，但不得复制进 `docs/specs/`，也不得改变 specs 的 `missing / draft / active` 判定。

## 可复用资料模板与显式初始化

项目接入时可按需使用项目根 `project-templates/README.md` 与 `project-templates/MANIFEST.tsv`。模板源只定义资料结构和引用关系，不携带业务事实；`harness`、`requirements`、`design`、`docs`、`experience` domain 可独立生成。只有显式调用初始化器并提供安全的 `--module` 或 `--case` 标识时，才实例化对应模块/案例；不生成空业务资料，不创建 `_module.md` 或 `_case.md` 的业务副本。

模板顶层 `status: template` 仅表示模板源；生成物统一从 `template` 变为 `draft`，不能据此声称目标已确认、实现已观察或验收已通过。`{{ROOT}}`、`{{MODULE}}`、`{{CASE}}`、`{{DATE}}` 只做确定性的轻量替换；模板中的内容不执行为代码。生成资料应按需求 ID → 模块 → 实现 → 用例 → 偏差 → 证据建立引用，需求、实现和验收状态继续分离。前端事实仍以目标项目源码/运行证据为准，`docs/specs/` 只作索引和记录入口；文档与新鲜证据冲突时记录冲突和来源，不让陈旧文档覆盖事实。

生成物位于 `docs/specs/` 之外，并由目标项目根 `PROJECT_MAP.md` 登记；根 `MAP.md` 不随生成器改写。前端 specs、token 和公共验收规则分别引用目标项目已有 `docs/specs/`、`docs/token-specs/` 与 `docs/harness/verification.md`。未生成的可选跨域资料使用项目根 code 路径和 `pending`/`unverified` 状态说明，不能留下不可解析 Markdown 链接。

## 三个核心状态

同一需求至少必须分别表达确认、实现和证据；决策、计划与偏差按实际存在时追加：

1. 用户确认状态：用户是否确认了目标和范围；没有确认就保持 `pending`，不能把猜测写成目标。
2. 实现状态：源码是否已实现、部分实现或尚未找到证据；实现差距通过引用关联，不修改目标来掩盖差距。
3. 验收结果：按 [verification contract](./verification.md) 得出的 `pass`、`fail`、`blocked` 或 `unverified`；技术通过不等于用户业务决策已完成。

已确认规则只维护目标和稳定 ID 引用，不在规则记录中复制实现状态或验收结果。当前实现和偏差应引用具体源码、提交、命令或环境证据；不要在需求文档中复制一份会过期的实现描述。公共 QA 触发、角色、复验和升级边界唯一引用 [verification contract](./verification.md)，专项模板只记录关联 ID、实际结果和证据。

## 偏差闭环

偏差记录必须有 `open`、`in-fix`、`recheck`、`closed` 或 `blocked` 状态，并保留目标、实现引用、修复引用、复验证据、核对时间和下一步。修复后由原 QA 增量复验；没有新证据不得改为 `closed`。关闭偏差不删除历史失败、旧实现引用或用户决策，只追加结果和来源。

## 最小记录格式

需要记录时，保持一条稳定需求编号一份目标记录，并补齐可追溯信息：

```text
ID: REQ-<稳定编号>
目标: <用户确认的结果和范围>
用户确认状态: confirmed | pending | rejected | superseded
实现状态: not-started | partial | observed | not-found
实现引用: <文件、行号、命令或提交>
差距: <目标与实现的差异；没有差距写 none>
验收结果: pass | fail | blocked | unverified
证据: <测试/运行命令、环境、提交或截图引用>
核对时间: <YYYY-MM-DD 或含时区时间>
未验证范围: <没有覆盖的端、权限、数据或交互>
来源: <用户、PRD、源码或环境证据>
```

需求编号一经使用不重排、不复用。若目标变更，保留原记录并新增决策或版本说明；若实现变更，更新实现引用和核对时间，不改写历史用户确认。

## 何时建文件与导航

- 默认先更新已有资料，不为单个占位符创建空的需求、ADR、证据或业务 specs 文件。
- 显式初始化是唯一的 draft 骨架例外：调用方明确选择 domain，并按需提供安全的 `--module` 或 `--case` 时，可以创建 `status: draft` 的结构文件并登记到 `PROJECT_MAP.md`；骨架不是业务事实，不得把生成动作写成已确认目标、已观察实现或验收通过。
- 除上述显式初始化例外外，只有真实存在且被任务需要的需求、决策或环境资料才建立；建成后从项目自己的 MAP 或领域 INDEX 导航。
- `docs/harness/` 只维护通用契约；项目事实、目标和证据的详细内容留在接入项目中。
- 若资料、权限、环境或用户决策缺失，记录 `pending`/`blocked` 和所需输入，不用猜测补齐。
