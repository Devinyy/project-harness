# CLAUDE.md

## 共享规则

先阅读同目录 `AGENTS.md`。它是 active/draft/missing 共享状态、边界（含 `13_AGENT_POLICY.md`）、危险区和验证的唯一来源；不要在此复制。

## Claude Code 入口

- specs 缺失时运行 `/init-specs`。
- 任务 playbook 位于 `.claude/commands/<name>.md`：`new-page`、`debug`、`refactor`、`review`、`tech-solution`。
- hooks 使用 active specs 的 `dangerous-zones.txt` 与 verification profile，不得绕过。

## 最终检查

复查 diff，运行匹配验证；无法执行时说明原因和建议命令。
