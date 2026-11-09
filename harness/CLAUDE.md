# CLAUDE.md

## 共享规则

先阅读同目录 `AGENTS.md`。它是 active/draft/missing 共享状态、边界（含 `13_AGENT_POLICY.md`）、危险区和验证的唯一来源；不要在此复制。
静态工具导航见 [MAP.md](./MAP.md)，接入项目后的资料索引见根 `PROJECT_MAP.md`，通用验收见 [docs/harness/verification.md](./docs/harness/verification.md)。

## Claude Code 入口

- specs 缺失时运行 `/init-specs`。
- 任务 playbook 位于 `.claude/commands/<name>.md`：`new-page`、`debug`、`refactor`、`review`、`tech-solution`。
- 危险区 hook 读取 `dangerous-zones.txt`（缺失时使用兜底）。Stop hook 经 `verify-harness.sh`：harness 自检时运行测试；项目 specs 为 `active` 时运行 fast profile；非 active 时失败关闭。不得绕过拦截。

## 最终检查

复查 diff，运行匹配验证；无法执行时说明原因和建议命令。
