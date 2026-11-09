# Project knowledge templates

`project-templates/` 是可按需生成的项目资料包，不是业务事实库。它补齐需求、实现、设计、环境证据、验收与发布记录的结构；真实项目仍由源码、已确认需求、运行环境和用户决策提供事实。

## Domains

| Domain | 入口 | 用途 |
| --- | --- | --- |
| `harness` | [harness/MAP.md](./harness/MAP.md) | 架构决策、当前实现、命名、验收用例、偏差和场景流程 |
| `requirements` | [requirements/MAP.md](./requirements/MAP.md) | 需求概览、确认规则、模块链路；模块按需实例化 |
| `design` | [design/MAP.md](./design/MAP.md) | token 来源、交互约束和设计目标 |
| `docs` | [docs/MAP.md](./docs/MAP.md) | 环境、接口联调、后端证据、发布与回滚证据 |
| `experience` | [experience/MAP.md](./experience/MAP.md) | 可选的 aibrain、键盘事件、复盘和 badcase 记录 |

机器可读入口是 [MANIFEST.tsv](./MANIFEST.tsv)。它固定为三列 Tab 分隔：`domain`, `path`, `kind`，不带表头；允许 `#` 注释。`domain` 只能是 `harness`、`requirements`、`design`、`docs`、`experience`，`kind` 只能是 `static`、`module`、`case`。

## 生成约定

- `static` 按清单原路径生成；`module` 只把 `requirements/modules/_module.md` 实例化为 `requirements/modules/<module>.md`；`case` 只把 `badcase/_case.md` 实例化为 `badcase/<case>.md`。
- 模板使用 `{{ROOT}}`、`{{MODULE}}`、`{{CASE}}`、`{{DATE}}` 四个符号。`{{ROOT}}` 是相对目标项目根的路径：根层使用 `./`，下一层使用 `../`，更深层依次增加 `../`；其余内容不得执行。
- 所有生成文档的顶层状态为 `draft`；模板本身保持 `status: template`。生成记录不能声称目标已确认、实现已观察或验收已通过。
- 模块与案例名称必须由初始化器校验为安全标识；模板不预先创建 `_module.md` 或 `_case.md` 的业务副本。
- 静态文件只链接同一 domain 内始终生成的文件。跨 domain、前端 specs、token 和公共规则使用项目根 code 路径及“按需生成/未验证”说明，避免只生成部分 domain 时出现坏链接。

## 追溯链

一条需求只保留一份目标记录，按稳定 ID 关联：

```text
需求 ID → requirements/modules/<module>.md
        → 实现位置（harness/impl.md + docs/specs/ 前端事实）
        → 用例 ID（harness/test-spec.md）
        → 偏差 ID（harness/deviations.md）
        → 环境/接口/发布证据（docs/）
```

前端实现事实继续使用现有 `docs/specs/INDEX.md`、`00_PROJECT_FACTS.md`、`02_ARCHITECTURE.md`、`04_CODING_STANDARDS.md`、`06_UI_COMPONENT_GUIDE.md` 和 `07_API_CONTRACTS.md`；不在本包复制字段、token、权限或组件正文。通用验收唯一来源仍是项目根 `docs/harness/verification.md`。

## 维护边界

需求确认、实现变更、接口变化、偏差修复、验收和发布完成时，按各 domain MAP 更新受影响资料。没有真实来源时保留 `pending`、`blocked` 或 `unverified`，不创建空业务记录；历史决策、失败和关闭证据只追加，不静默删除。
