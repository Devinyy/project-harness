# Harness 常驻上下文收敛 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 Codex 与 Claude Code 的常驻根指令收敛为可操作的导航和关键边界，同时以自动化测试防止再次膨胀。

**Architecture:** `AGENTS.md` 是跨 agent 的唯一常驻规则入口，承载 specs 状态、少量边界和按需资料路由。`CLAUDE.md` 只声明 Claude Code 的补充入口并显式转向 `AGENTS.md`。任务流程与项目事实继续留在 command playbook 和 `docs/specs/`，不再复制到根指令。

**Tech Stack:** Markdown、Bash、仓库现有 TAP 风格 shell 测试。

---

### Task 1: 为最小根指令写失败测试

**Files:**
- Modify: `harness/tests/harness/test-context-guidance.sh`

- [ ] **Step 1: 在上下文测试末尾加入常驻指令的路由与长度断言**

```bash
agents=$(sed -n '1,140p' "$HARNESS_ROOT/AGENTS.md")
assert_contains "$agents" "docs/specs/00_PROJECT_FACTS.md" "AGENTS routes agents to active project facts"
assert_contains "$agents" "docs/specs/11_DANGEROUS_AREAS.md" "AGENTS routes dangerous work to the dangerous-area guide"
assert_contains "$agents" "run-verification-profile.sh" "AGENTS routes agents to verification"
assert_contains "$agents" ".claude/commands/<name>.md" "AGENTS routes task details to playbooks"
assert_not_contains "$agents" "基座 `apps/micro-main` + 子应用" "AGENTS does not preload PC implementation details"

claude=$(sed -n '1,100p' "$HARNESS_ROOT/CLAUDE.md")
assert_contains "$claude" "AGENTS.md" "CLAUDE routes shared rules to AGENTS"
assert_contains "$claude" "/init-specs" "CLAUDE exposes the Claude initialization command"
assert_not_contains "$claude" "## 思维方式" "CLAUDE does not preload generic reasoning slogans"

agents_line_count=$(awk 'END { print NR }' "$HARNESS_ROOT/AGENTS.md")
if [ "$agents_line_count" -le 45 ]; then
  pass "AGENTS stays within its 45-line context budget"
else
  fail "AGENTS stays within its 45-line context budget (expected<=45 actual=$agents_line_count)"
fi
claude_line_count=$(awk 'END { print NR }' "$HARNESS_ROOT/CLAUDE.md")
if [ "$claude_line_count" -le 20 ]; then
  pass "CLAUDE stays within its 20-line context budget"
else
  fail "CLAUDE stays within its 20-line context budget (expected<=20 actual=$claude_line_count)"
fi
```

- [ ] **Step 2: 运行单个测试，确认因尚未收敛而失败**

Run: `bash tests/harness/test-context-guidance.sh`

Expected: FAIL，指出尚未出现新的最小入口文本、仍含 PC 实现细节或超出行数预算。

- [ ] **Step 3: 提交测试红灯基线**

```bash
git add tests/harness/test-context-guidance.sh
git commit -m "test(harness): define minimal context contract"
```

### Task 2: 收敛跨 agent 的根入口

**Files:**
- Modify: `harness/AGENTS.md`
- Test: `harness/tests/harness/test-context-guidance.sh`

- [ ] **Step 1: 用下列最终入口内容替换 `AGENTS.md`（不超过 45 行；最终为 32 行）**

```markdown
# AGENTS.md

所有 AI 编码 agent 的共享入口；Claude Code 用户同时阅读 `CLAUDE.md`。

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
| UI | `docs/token-specs/README.md`、`docs/token-specs/Light.tokens.json`、`docs/token-specs/antd-vue-theme.ts`；有 Figma 链接或截图时参照相关 playbook 完成列表 / 新建编辑 / 详情的视觉验收 |
```

- [ ] **Step 2: 运行目标测试，确认新契约通过**

Run: `bash tests/harness/test-context-guidance.sh`

Expected: PASS，所有既有 specs 状态断言与新增最小入口断言通过；`AGENTS.md` 不超过 45 行（最终为 32 行）。

- [ ] **Step 3: 提交跨 agent 根入口**

```bash
git add AGENTS.md tests/harness/test-context-guidance.sh
git commit -m "refactor(harness): minimize shared agent context"
```

### Task 3: 收敛 Claude 专属入口并跑全量验证

**Files:**
- Modify: `harness/CLAUDE.md`
- Test: `harness/tests/harness/test-context-guidance.sh`

- [ ] **Step 1: 用下列 Claude 专属入口替换 `CLAUDE.md`（上限 20 行）**

```markdown
# CLAUDE.md

## 共享规则

先阅读同目录 `AGENTS.md`。它是项目事实状态、跨项目边界、危险区和验证入口的唯一共享规则来源；不要在本文件复制其内容。

## Claude Code 入口

- specs 缺失时运行 `/init-specs`；它负责脚手架与后续填充流程。
- 任务需要现成 playbook 时，打开 `.claude/commands/<name>.md`：`new-page`、`debug`、`refactor`、`review`、`tech-solution`。
- 危险区 hook 读取 `dangerous-zones.txt`，缺失时使用兜底；Stop hook 经 `verify-harness.sh`：harness 自检时运行测试，项目 specs 为 `active` 时运行 fast profile，非 active 时失败关闭；不要绕过拦截。

## 最终检查

修改完成后复查 diff，运行与任务匹配的验证；无法执行时说明原因和建议命令。
```

- [ ] **Step 2: 运行全部 harness 测试与空白检查**

Run: `git diff --check && bash tests/harness/run.sh`

Expected: exit code 0；所有 TAP 断言通过。

- [ ] **Step 3: 查看最终体积和 staged diff**

Run: `wc -l AGENTS.md CLAUDE.md && git diff --check && git diff --stat`

Expected: `AGENTS.md` 不超过 45 行、`CLAUDE.md` 不超过 20 行，且无空白错误。

- [ ] **Step 4: 提交 Claude 入口及全量验证结果**

```bash
git add CLAUDE.md tests/harness/test-context-guidance.sh
git commit -m "refactor(harness): simplify Claude context entrypoint"
```
