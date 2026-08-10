# Harness 常驻上下文收敛设计

## 目标

将 Codex 与 Claude Code 启动时加载的根指令收敛为导航与关键边界，避免重复流程、无关项目类型信息和泛化行为口号占用上下文；保留 `docs/specs/`、命令 playbook 和模板作为按需读取的事实来源。

## 范围

本次修改仅覆盖 `AGENTS.md`、`CLAUDE.md` 及其自动化回归测试。不会删除项目 specs、token 模板、命令 playbook 或 hooks；不会改变 specs 的 `active/draft/missing` 状态语义和危险区拦截机制。

## 方案

### 1. 根指令成为最小入口

`AGENTS.md` 只保留：

- specs 状态判定与初始化入口；
- 少量跨项目、不可违背的开发边界；
- 危险区、验证和按需资料的路由；
- 任务类型到 playbook/spec 的简短映射。

不再内联两类项目的完整技术栈、各任务逐步操作说明、UI/token 细节或重复的禁止清单。

### 2. Claude 文件仅保留 Claude 差异

`CLAUDE.md` 明确以 `AGENTS.md` 为共享规则来源，只补充 Claude Code 的 slash command 和可发现入口。删除与 `AGENTS.md` 重复的项目状态、架构、禁令、思维口号及强制过程仪式。

### 3. 外置知识按需读取

项目事实仍由已激活的 `docs/specs/00_PROJECT_FACTS.md` 与 `INDEX.md` 供给；具体任务打开相应 `.claude/commands/<task>.md` 和 specs。UI/token、项目类型与框架差异只在相关任务时读取。

### 4. 防回归测试

更新上下文指导测试，验证：

- 根 `AGENTS.md` 保留 specs 状态、危险区、验证和任务路由；
- `CLAUDE.md` 路由至共享指令与 Claude 命令；
- 两份常驻指令保持各自的行数上限；
- 已外置的任务细节仍由 command/spec 文件承载。

## 验收

1. Codex 可只通过 `AGENTS.md` 判断 specs 是否可用、何时读取危险区、何处查任务流程和验证命令。
2. Claude Code 可通过 `CLAUDE.md` 进入共享规则及 slash command，而无需加载重复手册。
3. PC/uni-app 的具体约束仍可从 active specs 取得。
4. `bash tests/harness/run.sh` 通过，且 `git diff --check` 无错误。

## 风险与处理

- 过度裁剪可能隐藏关键边界：只移除重复和任务专属细节，保留状态、授权、危险区与验证入口。
- 文档链接可能失效：测试固定关键路由文本，并沿用仓库已有路径。
- 旧 agent 可能只读取 `CLAUDE.md`：其中显式要求先读同目录 `AGENTS.md`。
