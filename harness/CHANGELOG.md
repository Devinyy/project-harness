# Changelog

本文件记录 Project Harness 的版本变更。遵循「机制改动写清楚为什么」。

## v2.9 — 通用分层基线 + 组件拆分门禁

针对两个长期缺口：架构模型从未在 harness 层显式表述、页面缺乏拆分约束（实测会写出近千行单文件）。

- **`02_ARCHITECTURE` 增「通用分层模型（MVVM）」固定基线**：两套 flavor 顶部各加一段不随项目改写的分层约定——View / ViewModel / Model / 基础设施四层 + 依赖方向红线 + 各层边界 + 反模式。*为什么*：原 `02_ARCHITECTURE` 通篇 `<填写>` 占位符，MVVM 分层只散落在 `CLAUDE`/`AGENTS` 的零碎规则里、从无一处完整表述，agent 缺统一架构锚点。尊重 flavor 差异：PC 用 Pinia `apps/*/src/store/`，uni-app 禁 stores、只用 composable。
- **`05_COMPONENT_PATTERNS` 的「拆分原则」从占位符写成可判定规则**：何时必须拆（单 `.vue` > 500 行 / `<template>` ≥3 语义区块 / 重复结构 ≥2 次 / `v-for` item > 30 行 / 弹窗表单）+ 页面只做编排（业务逻辑抽 `useXxxPage`）+ 不要拆过头（小程序 setData/通信开销）。*为什么*：原「拆分原则」是空占位符，且「复用优先/不发明新架构」被 agent 误读成「少新建文件」，正反信号叠加导致巨型页面；显式写明「抽子组件≠发明新架构」调和。
- **新增 `check-large-file.sh`（PostToolUse，advisory）**：写入 `.vue` > 500 行即提示按拆分原则拆分，exit 2 不回滚，与 `check-box-sizing` 同模式。*为什么*：按 harness 迭代原则「加固 harness 而非改提示词」，给事后纠偏门禁兜底。
- **`/new-page` 增「拆分预判」步、`/review` 增「组件粒度/巨型文件」检查项**，并同步根 `AGENTS.md` 标准流程与目录级 `AGENTS.md`（Codex/Cursor/Windsurf 同样吃到，不只 Claude）。

## v2.8.1 — 接入健壮性修复

针对 v2.8 接入真实项目时暴露的问题：

- **初始化语义统一**：README 原说「若 `docs/specs/` 不存在」，与 AGENTS/CLAUDE/脚本的「以 `docs/specs/00_PROJECT_FACTS.md` 是否存在为准」不一致 → README 改为统一口径（空目录不算已初始化）。
- **类型检查命令不再写死 `vue-tsc`**：`verify-before-stop.sh`（Claude + Codex）改为按优先级解析——`docs/specs/verify.cmd` → 探测 `package.json` 脚本（`lint:type`/`validate`/`type-check`/`typecheck`/`check`）→ 兜底 `pnpm exec vue-tsc --noEmit`。`init-specs.sh` 接入时自动探测并写 `docs/specs/verify.cmd`（供人工修正，如 monorepo filter）。解决真实项目误报/用错命令。
- **危险区扫描健壮化**：Codex `verify-before-stop.sh` 原把多行 patterns 直接喂 `grep -F "$VAR"`（多行/平台行为不稳，可能漏报）→ 改为 `grep -F -f <(过滤注释空行)`，稳妥逐行子串匹配。
- **Codex hook matcher 放宽 + 校验说明**：`config.toml` 的 `matcher` 由 `"^Bash$"` 放宽为 `"Bash|shell|exec_command|local_shell"`（hook 内部已用 `jq '.tool_input.command // empty'` 自过滤，偏宽不误伤）。并加注释：hooks 协议字段与工具名需按所装 Codex 版本核验（本配置未在真实 Codex 上验证），附校验方法。
- **文档区分「脚手架」与「填充」**：明确 `scripts/init-specs.sh` 只复制骨架（产物全是占位符），只有 Claude `/init-specs` 才接着自动探索填充；其它 agent 需自行驱动填充。
- **`doctor.sh` 新增 `--strict`**：默认 specs 未填/占位残留只 warning（适合草稿期）；`--strict` 下升级为 fail（适合团队/CI 闸门），并新增「`status: draft/template` 未复核」检查。

## v2.8 — specs 外置 + 自带模版骨架

- harness 不内置任何项目真实 specs，改为可见的根目录 `spec-templates/`（不藏 `.claude/` 下），含 `SCHEMA.md` + PC 微前端 / uni-app 多端两套**全覆盖骨架**（`00..12` + `INDEX` + `dangerous-zones.txt` + 组件库索引 + `examples/` + `skills-reference/` + 目录级 `AGENTS/`），A 精炼版（保留结构、正文挖空为占位符）。
- 新增 `/init-specs`（Claude）+ `scripts/init-specs.sh`（跨 agent）：探测 flavor → 复制骨架到项目根 `docs/specs/` → 镜像放置目录级 AGENTS。
- 危险区改为 specs 驱动：guard / verify hook 读 `docs/specs/dangerous-zones.txt`，缺失时用通用兜底。
- `doctor.sh` 自检/项目双模式（harness 包内自检不再因缺 `package.json` 失败）。
- `CLAUDE.md`/`AGENTS.md`/commands 通用化（不内联具体项目事实）；`AGENTS.md` 增「标准流程」供 Codex/Cursor/Windsurf 遵循。
- 两套现成 specs（dc-platform / ecm-welfare）移出 harness 单独分发。

## v2.7 — 双项目统一

- 整合 dc-platform（micro-app/dcgj-ui）+ ecm-welfare（uni-app/uview-plus）两个不同栈 Vue3 项目到一套 harness。
- hooks 项目自适应：类型检查统一 `vue-tsc`、`check-box-sizing` 门禁 uni-app、危险区取两项目并集；`format` 支持 `.vue`。

## v2.6 / v2.5 / v2.4 / v2.3 / v2.0

- v2.6：CLAUDE.md 增「你的角色」「上下文纪律」「失败熔断」；commands 增 per-task 角色锚定、`cat`→`head`/`grep`。
- v2.5：`.codex/config.toml` 删写死 model；commands 写死命令改为引用 CLAUDE.md。
- v2.4：`npx`→`pnpm exec`；Codex hooks JSON 输出消毒；Stop hook 格式化兜底；README 增「常见接入失败原因」。
- v2.3：doctor 移至 `scripts/` 并作 SessionStart hook；新增 `/review`；Codex Stop hook 危险区兜底扫描。
- v2.0：从 7782 行 specs 体系重构为 harness 配置；4 hooks + 4 commands；双 agent 支持。
