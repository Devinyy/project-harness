# AGENTS.md

所有 AI 编码 agent 的共享入口；Claude Code 用户同时阅读 `CLAUDE.md`。
总导航：[MAP.md](./MAP.md)；通用知识与验收契约：[docs/harness/knowledge.md](./docs/harness/knowledge.md)、[docs/harness/verification.md](./docs/harness/verification.md)。

## Specs 状态

- **active**：`docs/specs/00_PROJECT_FACTS.md` 存在、无 `<填写…>` 等占位符且文档状态均为 `active`，才是项目事实；先读它与 `docs/specs/INDEX.md`。
- **draft**：有骨架、占位符或 `draft/template` 状态时，不得当作项目事实；按 `docs/specs/_RULE.md` 填充并人工复核。
- **missing**：缺少 `00_PROJECT_FACTS.md`（即使有空 `docs/specs/` 目录）时，Claude Code 运行 `/init-specs`；其余运行 `bash scripts/init-specs.sh`，再按 `_RULE.md` 填充并人工复核。

不得全量加载 specs，也不得把模板当作项目事实。

## 授权

Specs 为 active 时，任何可能涉及授权边界的动作前先读 `docs/specs/13_AGENT_POLICY.md`：`Allowed` 在用户范围内执行，`Ask First` 先取得同意，`Blocked` 不执行。

## 边界

1. 先读现有实现与项目事实，优先复用已有模式、组件和封装。
2. 不得编造字段、API、目录、框架或 UI；语义不明时询问，或标记 `TODO`。
3. 无明确需求，不改公共基础设施、认证/请求封装、全局配置或无关代码。
4. 完成前验证，并披露未执行的验证及原因。

## 按需路由

| 需要 | 读取或执行 |
| --- | --- |
| 任务流程 | `.claude/commands/<name>.md` playbook |
| 项目文档 | `docs/specs/INDEX.md`，再按需读取 |
| 危险区 | `docs/specs/11_DANGEROUS_AREAS.md` 与 `docs/specs/dangerous-zones.txt` |
| 验证 | `bash scripts/run-verification-profile.sh fast`；需要时用 `full` |
| UI | `docs/specs/06_UI_COMPONENT_GUIDE.md`；有 Figma 链接或截图时参照相关 playbook 完成列表 / 新建编辑 / 详情的视觉验收 |
| 可复用资料 | `project-templates/README.md`、`project-templates/MANIFEST.tsv`；显式生成用 `bash scripts/init-project-knowledge.sh ...` |

通用验收按 `docs/harness/verification.md` 执行；任务专项步骤仍以 `.claude/commands/<name>.md` 为准。
