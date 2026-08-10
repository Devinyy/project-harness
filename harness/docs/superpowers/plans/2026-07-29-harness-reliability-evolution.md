# Harness Reliability Evolution Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Evolve the repository-level coding-agent control pack into a reliable, testable, and evidence-driven external harness without prematurely building a full agent runtime.

**Architecture:** Work in five ordered stages: first make existing facts and hooks trustworthy, then broaden verification, then add human-policy and audit feedback, and only add long-running orchestration when real traces justify it. Each stage must be independently releasable and must not depend on later stages.

**Tech Stack:** Bash, jq, Git, Markdown, existing Claude Code/Codex hook protocols; no new package dependency.

## Global Constraints

- Preserve the current Claude Code / Codex / Cursor / Windsurf entry points.
- Do not modify or delete user-owned `docs/specs/` and `docs/token-specs/` content while changing the harness.
- Do not add a test framework dependency; shell contract tests run with Bash and temporary fixtures.
- Keep `spec-templates/` as the source for generated project specs.
- Treat project facts as usable only when their readiness state is `active`; file existence alone is insufficient.
- Do not add MCP, multi-agent orchestration, checkpoints, or persistent task state until Stage 5 entry criteria are met.
- Every behavior change requires a failing contract test first.

---

## Evolution order

| Stage | Outcome | Entry condition | Exit gate |
|---|---|---|---|
| 1 | Existing context and hooks become trustworthy | Current v2.9 baseline | All known P0 defects have regression tests |
| 2 | Hook behavior is portable and fully covered | Stage 1 green | Claude/Codex contract matrix green |
| 3 | “Done” means verified behavior, not only type safety | Stage 2 green | Fast/full verification profiles work in both flavors |
| 4 | Human decisions and failures become auditable feedback | Stage 3 green | Ask-First policy and sanitized audit records are usable |
| 5 | Add only evidence-backed long-running capabilities | At least 20 real task traces | Each new component proves measurable value |

---

### Task 1: Introduce a shared specs-readiness contract

**Files:**
- Create: `scripts/lib/specs-state.sh`
- Create: `tests/harness/testlib.sh`
- Create: `tests/harness/test-specs-state.sh`
- Create: `tests/harness/run.sh`
- Modify: `scripts/init-specs.sh`
- Modify: `scripts/doctor.sh`
- Modify: `AGENTS.md`
- Modify: `CLAUDE.md`
- Modify: `.cursor/rules/project-harness.mdc`
- Modify: `.windsurfrules`
- Modify: `README.md`

**Interfaces:**
- Produces: `specs_state <project-root>`, printing exactly `missing`, `draft`, or `active`.
- `missing`: `docs/specs/00_PROJECT_FACTS.md` does not exist.
- `draft`: the facts file exists, but any specs file contains a known placeholder or any declared frontmatter status is `draft`/`template`.
- `active`: the facts file exists, no known placeholder remains, and every declared status is `active`.

- [ ] **Step 1: Write failing readiness tests**

Add fixtures for `missing`, placeholder-bearing `draft`, status-bearing `draft`, and fully reviewed `active`. Assert the exact state string and process exit code.

- [ ] **Step 2: Run the focused test and confirm the current implementation fails**

Run: `bash tests/harness/test-specs-state.sh`

Expected: FAIL because `scripts/lib/specs-state.sh` does not exist.

- [ ] **Step 3: Implement the minimum shared readiness function**

Use fixed-string placeholder checks for `<填写`, `<生成时填写>`, and `<项目名>`. Do not treat files without frontmatter as invalid.

- [ ] **Step 4: Replace existence-only branches**

Apply the shared state consistently:

- `missing` → scaffold.
- `draft` → never overwrite; direct the agent to continue filling and reviewing.
- `active` → skip initialization and allow normal work.
- `doctor --strict` → fail for `missing` and `draft`.
- Session guidance → read project facts as authoritative only for `active`.

- [ ] **Step 5: Run readiness and shell syntax tests**

Run: `bash tests/harness/test-specs-state.sh && bash -n scripts/lib/specs-state.sh scripts/init-specs.sh scripts/doctor.sh`

Expected: all assertions pass; Bash exits 0.

- [ ] **Step 6: Commit Stage 1A**

Run: `git add scripts/lib/specs-state.sh tests/harness AGENTS.md CLAUDE.md .cursor/rules/project-harness.mdc .windsurfrules README.md scripts/init-specs.sh scripts/doctor.sh && git commit -m "fix(harness): enforce specs readiness contract"`

Expected: one commit containing only readiness behavior, tests, and synchronized guidance.

---

### Task 2: Fix Codex context loading and self-hosting verification

**Files:**
- Create: `scripts/verify-harness.sh`
- Create: `tests/harness/test-codex-context.sh`
- Create: `tests/harness/test-self-verification.sh`
- Modify: `.codex/config.toml`
- Modify: `.claude/hooks/verify-before-stop.sh`
- Modify: `.codex/hooks/verify-before-stop.sh`
- Modify: `tests/harness/run.sh`

**Interfaces:**
- Produces: `scripts/verify-harness.sh --self|--project`.
- `--self`: runs the harness shell contract suite and never invokes pnpm.
- `--project`: runs the command declared by the active project specs.
- Auto mode: self when `spec-templates/` exists and `package.json` does not; project otherwise.

- [ ] **Step 1: Write failing tests for both reproduced defects**

Assert that `AGENTS.md` byte length is not greater than `project_doc_max_bytes`. Assert that self verification does not execute a fake `pnpm` placed first on `PATH`.

- [ ] **Step 2: Run tests and confirm both fail on v2.9**

Run: `bash tests/harness/test-codex-context.sh; bash tests/harness/test-self-verification.sh`

Expected: context-size assertion fails and current Stop verification reaches pnpm.

- [ ] **Step 3: Raise the Codex document limit**

Set `project_doc_max_bytes = 8192`. Keep the static contract test so later growth cannot silently exceed the configured limit.

- [ ] **Step 4: Centralize self/project verification**

Make both Stop hook adapters delegate to `scripts/verify-harness.sh`. Keep protocol-specific JSON/exit behavior inside the adapters; keep verification selection in the shared script.

- [ ] **Step 5: Run the full Stage 1 suite**

Run: `bash tests/harness/run.sh`

Expected: readiness, context-size, self-verification, and shell syntax checks all pass.

- [ ] **Step 6: Commit Stage 1B**

Run: `git add .codex/config.toml scripts/verify-harness.sh .claude/hooks/verify-before-stop.sh .codex/hooks/verify-before-stop.sh tests/harness && git commit -m "fix(harness): make verification self-aware"`

Expected: no business-project specs or generated specs are included.

---

### Task 3: Build a cross-agent hook contract matrix

**Files:**
- Create: `scripts/lib/changed-files.sh`
- Create: `.codex/hooks/guard-dangerous-zones.sh`
- Create: `tests/harness/test-claude-hooks.sh`
- Create: `tests/harness/test-codex-hooks.sh`
- Create: `tests/harness/test-changed-files.sh`
- Modify: `.codex/config.toml`
- Modify: `.codex/hooks/format-on-write.sh`
- Modify: `.codex/hooks/verify-before-stop.sh`
- Modify: `.claude/hooks/guard-dangerous-zones.sh`
- Modify: `tests/harness/run.sh`

**Interfaces:**
- Produces: `changed_files <git-root>`, returning the union of staged, unstaged, and untracked non-ignored files exactly once.
- Codex PreToolUse must cover canonical `Bash` and `apply_patch`/`Edit`/`Write` aliases.
- Repository-local hook commands resolve from `git rev-parse --show-toplevel`, not the current subdirectory.

- [ ] **Step 1: Write the protocol matrix tests**

Cover safe and blocked shell commands, dangerous and normal paths, edits from a nested working directory, an untracked dangerous file, malformed JSON, and empty input.

- [ ] **Step 2: Confirm current Codex coverage fails**

Run: `bash tests/harness/test-codex-hooks.sh && bash tests/harness/test-changed-files.sh`

Expected: FAIL for apply-patch coverage, nested-directory resolution, or untracked-file detection.

- [ ] **Step 3: Implement exact hook coverage**

Use Codex canonical hook input (`tool_input.command`) and accepted block output. Add a dedicated apply-patch dangerous-zone adapter rather than making the Bash command blocker parse patch content.

- [ ] **Step 4: Make changed-file discovery complete**

Union `git diff --name-only HEAD` with `git ls-files --others --exclude-standard`. Reuse this helper for formatting, danger scanning, and summaries.

- [ ] **Step 5: Run all contract tests**

Run: `bash tests/harness/run.sh`

Expected: all Claude, Codex, readiness, context, self-mode, and changed-file cases pass.

- [ ] **Step 6: Commit Stage 2**

Run: `git add scripts/lib .codex .claude/hooks tests/harness && git commit -m "test(harness): cover cross-agent hook contracts"`

Expected: a portable hook layer with no new dependency.

---

### Task 4: Expand verification into fast and full profiles

**Files:**
- Create: `scripts/run-verification-profile.sh`
- Create: `tests/harness/test-verification-profile.sh`
- Modify: `scripts/init-specs.sh`
- Modify: `spec-templates/SCHEMA.md`
- Modify: `spec-templates/pc-microapp/RULE.md`
- Modify: `spec-templates/miniprogram-uniapp/RULE.md`
- Modify: `.claude/hooks/verify-before-stop.sh`
- Modify: `.codex/hooks/verify-before-stop.sh`
- Modify: `README.md`

**Interfaces:**
- Consumes: existing `docs/specs/verify.cmd` as the backwards-compatible fast command.
- Produces: optional `docs/specs/verify.full.cmd`, one non-comment shell command per line.
- Stop hooks run the fast profile.
- Manual/CI invocation `bash scripts/run-verification-profile.sh full` runs fast checks followed by full checks.

- [ ] **Step 1: Write failing profile tests**

Cover ordered execution, comment/blank-line filtering, stop-on-first-failure, missing optional full profile, and backwards compatibility with only `verify.cmd`.

- [ ] **Step 2: Implement the profile runner**

Do not infer nonexistent test commands. Generate only commands found in the real project; leave unavailable categories documented as absent.

- [ ] **Step 3: Define flavor expectations**

PC projects should discover typecheck/lint/build and existing tests. Uni-app projects should discover typecheck/lint/build plus any existing platform smoke command; do not invent `pnpm test`.

- [ ] **Step 4: Add a baseline comparison mode**

Support `--snapshot <file>` and `--compare <file>` for command exit/name pairs. Comparison blocks newly failing commands while retaining pre-existing failures as visible warnings.

- [ ] **Step 5: Run profile tests and the entire harness suite**

Run: `bash tests/harness/test-verification-profile.sh && bash tests/harness/run.sh`

Expected: profile behavior and all earlier contracts pass.

- [ ] **Step 6: Commit Stage 3**

Run: `git add scripts tests/harness spec-templates README.md .claude/hooks .codex/hooks scripts/init-specs.sh && git commit -m "feat(harness): add staged verification profiles"`

Expected: verification expands without requiring every project to have identical scripts.

---

### Task 5: Make human policy and failure feedback explicit

**Files:**
- Create: `spec-templates/pc-microapp/13_AGENT_POLICY.md`
- Create: `spec-templates/miniprogram-uniapp/13_AGENT_POLICY.md`
- Create: `scripts/record-harness-event.sh`
- Create: `tests/harness/test-audit-record.sh`
- Modify: `spec-templates/SCHEMA.md`
- Modify: `spec-templates/pc-microapp/INDEX.md`
- Modify: `spec-templates/miniprogram-uniapp/INDEX.md`
- Modify: `AGENTS.md`
- Modify: `CLAUDE.md`
- Modify: `.claude/hooks/block-dangerous-commands.sh`
- Modify: `.claude/hooks/guard-dangerous-zones.sh`
- Modify: `.claude/hooks/verify-before-stop.sh`
- Modify: `.codex/hooks/block-dangerous-commands.sh`
- Modify: `.codex/hooks/guard-dangerous-zones.sh`
- Modify: `.codex/hooks/verify-before-stop.sh`
- Modify: `README.md`

**Interfaces:**
- Policy document has exactly three top-level sections: `Allowed`, `Blocked`, `Ask First`.
- Audit records append JSONL under `.git/harness/events.jsonl`.
- Records include timestamp, adapter, event, category, decision, and exit status.
- Records must not include raw prompts, full shell commands, file contents, tokens, or environment values.

- [ ] **Step 1: Write audit privacy and schema tests**

Feed events containing quotes, newlines, and secret-shaped values. Assert valid JSONL and absence of raw payloads.

- [ ] **Step 2: Add the shared policy template**

Put destructive operations, dependency installation, network egress, dangerous-zone edits, business-semantic uncertainty, and external writes into an explicit bucket.

- [ ] **Step 3: Add sanitized event recording**

Record hook blocks, verification failures, readiness failures, and explicit bypass/approval outcomes. Failure to record must never block the development task.

- [ ] **Step 4: Document the feedback loop**

Define a monthly review: group repeated categories, select only repeated failures, then choose whether to improve a guide, sensor, hook, or remove an obsolete rule.

- [ ] **Step 5: Run privacy tests and full suite**

Run: `bash tests/harness/test-audit-record.sh && bash tests/harness/run.sh`

Expected: valid sanitized records and no regression.

- [ ] **Step 6: Commit Stage 4**

Run: `git add spec-templates scripts tests/harness AGENTS.md CLAUDE.md README.md .claude .codex && git commit -m "feat(harness): add explicit policy and audit feedback"`

Expected: project-local audit evidence without repository noise or sensitive payloads.

---

### Task 6: Gate long-running capabilities behind trace evidence

**Files:**
- Create only after entry criteria are met: `docs/superpowers/plans/long-running-capability-experiment.md`
- Analyze: `.git/harness/events.jsonl`
- Analyze: at least 20 completed real-task traces

**Entry criteria:**
- Stages 1–4 have shipped and remained green.
- At least 20 representative page, debug, refactor, review, and technical-solution tasks have been observed.
- A failure category repeats at least 3 times and cannot be addressed by a smaller guide, sensor, or deterministic script.

- [ ] **Step 1: Classify repeated failures**

Use only sanitized categories and task outcomes. Do not infer a need for orchestration from task duration alone.

- [ ] **Step 2: Choose the smallest matching capability**

- Context loss across resumptions → structured handoff/checkpoint.
- Self-review optimism on high-value work → independent evaluator.
- Repeated external delivery omissions → deterministic workflow/MCP adapter.
- Parallel independent research bottleneck → context-isolated subagent.

- [ ] **Step 3: Define an A/B success metric**

Require a measurable improvement in completion rate, human rework, newly introduced verification failures, elapsed time, or token cost.

- [ ] **Step 4: Write a separate implementation plan**

The plan must add one capability only, preserve a control group, and include a removal condition.

- [ ] **Step 5: Run a subtraction review after adoption**

After the capability has enough traces, remove it if it adds cost or complexity without measurable benefit.

---

## Final release gate

- [ ] `bash tests/harness/run.sh` exits 0.
- [ ] `bash scripts/doctor.sh --self --strict` exits 0 in a clean-checkout fixture; the current user-owned untracked specs remain untouched and unstaged.
- [ ] Both flavor fixtures pass `init-specs → draft → active` transitions.
- [ ] Claude and Codex hook contract matrices pass from the repository root and a nested directory.
- [ ] No generated `docs/specs/` or `docs/token-specs/` files are staged.
- [ ] `git diff --check` produces no output.
- [ ] README and CHANGELOG describe the shipped stage and its reason.

## Explicit non-goals before Stage 5

- No general-purpose agent orchestration runtime.
- No mandatory multi-agent workflow.
- No database-backed memory or task state.
- No MCP server added merely to satisfy a theoretical checklist.
- No automatic external writes or deployment.
- No claim that tests alone prove business acceptance; high-risk behavior retains human review.
