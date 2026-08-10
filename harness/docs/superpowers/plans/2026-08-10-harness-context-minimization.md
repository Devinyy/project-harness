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

assert_equals "$(wc -l < "$HARNESS_ROOT/AGENTS.md" | tr -d ' ')" "45" "AGENTS stays within its 45-line context budget"
assert_equals "$(wc -l < "$HARNESS_ROOT/CLAUDE.md" | tr -d ' ')" "18" "CLAUDE stays within its 18-line context budget"
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

- [ ] **Step 1: 用下列 45 行入口内容替换 `AGENTS.md`**

```markdown
# AGENTS.md

跨 agent 共享入口（Claude Code / Codex / Cursor / Windsurf）。Claude Code 另读 `CLAUDE.md` 的专属入口。

## 先判断 specs 状态

项目事实只来自 `docs/specs/`：

- `active`：`00_PROJECT_FACTS.md` 存在、无 `<填写…>` 占位符且文档状态均为 `active`；先读 `00_PROJECT_FACTS.md` 与 `INDEX.md`。
- `draft`：有骨架、占位符或 `draft/template` 状态；不得将其当事实，按 `docs/specs/_RULE.md` 填充并等待人工复核。
- `missing`：缺少 `00_PROJECT_FACTS.md`；Claude Code 运行 `/init-specs`，其余 agent 运行 `bash scripts/init-specs.sh` 后按 `_RULE.md` 填充。

若 specs 为 `active`，在涉及授权边界的操作前读取 `docs/specs/13_AGENT_POLICY.md`：只在 `Allowed` 和用户任务范围内执行；`Ask First` 先征得明确同意；`Blocked` 不执行。

## 跨项目边界

- 改动前先读目标及其现有调用/同类实现；优先复用项目已有模式。
- 不编造字段、接口、目录、框架或 UI 库；业务语义不明时询问或留下 `TODO: 待确认`。
- 未获明确需求，不改公共基础设施、认证/请求封装、全局配置或无关代码。
- 页面和数据层遵循 active specs；完成前运行可用验证，并如实报告未执行项。

## 按需路由

| 情况 | 先读 |
| --- | --- |
| 新页面、排障、重构、审查、技术方案 | `.claude/commands/<name>.md`（所有 agent 均可按需打开） |
| 项目类型、架构、业务、规范、组件、接口、UI | `docs/specs/INDEX.md` 后只读取所需文档 |
| 路由、权限、认证、请求、构建或全局配置 | `docs/specs/11_DANGEROUS_AREAS.md`；危险路径见 `docs/specs/dangerous-zones.txt` |
| 验证 | `bash scripts/run-verification-profile.sh fast`；需要时再运行 `full` |
| UI/token | `docs/specs/06_UI_COMPONENT_GUIDE.md` 与 `docs/token-specs/README.md` |

禁止全量加载 specs 或把模板当项目事实。
```

- [ ] **Step 2: 运行目标测试，确认新契约通过**

Run: `bash tests/harness/test-context-guidance.sh`

Expected: PASS，所有既有 specs 状态断言与新增最小入口断言通过。

- [ ] **Step 3: 提交跨 agent 根入口**

```bash
git add AGENTS.md tests/harness/test-context-guidance.sh
git commit -m "refactor(harness): minimize shared agent context"
```

### Task 3: 收敛 Claude 专属入口并跑全量验证

**Files:**
- Modify: `harness/CLAUDE.md`
- Test: `harness/tests/harness/test-context-guidance.sh`

- [ ] **Step 1: 用下列 18 行 Claude 专属入口替换 `CLAUDE.md`**

```markdown
# CLAUDE.md

## 共享规则

先阅读同目录 `AGENTS.md`。它是项目事实状态、跨项目边界、危险区和验证入口的唯一共享规则来源；不要在本文件复制其内容。

## Claude Code 入口

- specs 缺失时运行 `/init-specs`；它负责脚手架与后续填充流程。
- 任务需要现成 playbook 时，打开 `.claude/commands/<name>.md`：`new-page`、`debug`、`refactor`、`review`、`tech-solution`。
- hooks 使用 active specs 的 `dangerous-zones.txt` 与 verification profile；不要绕过拦截。

## 最终检查

修改完成后复查 diff，运行与任务匹配的验证；无法执行时说明原因和建议命令。
```

- [ ] **Step 2: 运行全部 harness 测试与空白检查**

Run: `git diff --check && bash tests/harness/run.sh`

Expected: exit code 0；所有 TAP 断言通过。

- [ ] **Step 3: 查看最终体积和 staged diff**

Run: `wc -l AGENTS.md CLAUDE.md && git diff --check && git diff --stat`

Expected: `AGENTS.md` 为 45 行、`CLAUDE.md` 为 18 行，且无空白错误。

- [ ] **Step 4: 提交 Claude 入口及全量验证结果**

```bash
git add CLAUDE.md tests/harness/test-context-guidance.sh
git commit -m "refactor(harness): simplify Claude context entrypoint"
```
