# Project Harness（通用 · specs 外置 + 自动生成）

**版本：v2.9**　·　完整变更见 [`CHANGELOG.md`](./CHANGELOG.md)

把项目规格（specs）转化为可执行的 AI agent 约束（harness）。支持 Claude Code / Codex / Cursor / Windsurf。

**核心理念：harness 不内置任何项目的真实 specs，只带「生成规则」（`spec-templates/`）。**
- specs 由每个项目在自己根目录的 `docs/specs/` 维护。
- Specs 使用 `missing / draft / active` 三态，不再用单个文件是否存在代表可用：
  - `missing`：facts 不存在 → 见下方「初始化」。
  - `draft`：骨架存在但有占位符、未复核状态 → 继续填充，不得作为项目事实。
  - `active`：facts 存在、无占位符、状态均为 `active` → agent 才能先读 facts + `INDEX.md` 作为真实事实。
- 危险区等机制由 specs **驱动**（hook 读 `docs/specs/dangerous-zones.txt`，验证读取 fast `verify.cmd` 与可选 full `verify.full.cmd`），harness 本体保持通用、可移植。
- **架构/组件约定是固定基线**：`spec-templates` 的 `02_ARCHITECTURE`（MVVM 通用分层模型）与 `05_COMPONENT_PATTERNS`（拆分原则）带不随项目改写的固定段，项目只在其上补特例——跨项目架构一致，且组件拆分有可判定规则（配 `check-large-file.sh` 门禁）。

## 目录布局（harness 内容直接放项目根）

```
你的项目根/
├── CLAUDE.md                 # 通用：角色 + 原则 + "先读 docs/specs/，无则 /init-specs"
├── AGENTS.md                 # 跨 agent 共享指令
├── .cursor/rules/ .windsurfrules
├── .claude/                   # Claude Code 专属
│   ├── settings.json
│   ├── commands/              #   /init-specs /new-page /debug /refactor /review /tech-solution
│   └── hooks/                 #   guard / block / format / box-sizing / large-file / verify(fast profile)
├── .codex/{config.toml, hooks/}   # Codex 专属
├── scripts/
│   ├── doctor.sh              # 自检/项目双模式：检测环境 + docs/specs 是否就绪
│   ├── init-specs.sh          # 👈 跨 agent 脚手架：复制骨架→docs/specs/ + 放置 AGENTS
│   ├── run-verification-profile.sh # fast/full 执行与 baseline snapshot/compare
│   ├── record-harness-event.sh # 匿名结构化审计事件，写入 git 私有目录
│   └── record-permission-outcome.sh # PostToolUse 可观察授权模式审计
├── spec-templates/            # 👈 可见、agent 中立的模版骨架（生成 docs/specs 的全部依赖，随 harness 走）
│   ├── SCHEMA.md              #   通用规则：要哪些文件、各写什么、dangerous-zones.txt 格式
│   ├── pc-microapp/           #   PC 微前端 flavor —— 全套骨架（提炼自 dc-platform）
│   │   ├── RULE.md            #     探索+填充说明
│   │   ├── 00_PROJECT_FACTS.md … 13_AGENT_POLICY.md  INDEX.md  dangerous-zones.txt
│   │   ├── dcgj-components/  examples/  skills-reference/
│   │   └── AGENTS/           #     apps/ · apps/micro-main/ · packages/ 目录级 AGENTS 模版（镜像放置）
│   └── miniprogram-uniapp/    #   uni-app 多端 flavor —— 全套骨架（提炼自 ecm-welfare）
│       ├── RULE.md
│       ├── 00_PROJECT_FACTS.md … 13_AGENT_POLICY.md  INDEX.md  dangerous-zones.txt
│       ├── uview-components/  examples/  skills-reference/
│       └── AGENTS/           #     src/api · src/components · src/composables · src/utils
├── token-templates/           # PC 设计 token 模板（初始化时复制到 docs/token-specs/）
│   └── pc/
│       ├── Light.tokens.json
│       ├── antd-vue-theme.ts
│       └── README.md
└── docs/specs/                # ← 由 /init-specs（或 scripts/init-specs.sh）复制骨架+填充生成（不随 harness 分发）
└── docs/token-specs/          # ← PC flavor 初始化时生成，色号/字号/主题 token 以此为准
```

> 模版放在**可见的根目录 `spec-templates/`**（不藏在 `.claude/` 下），Codex / Cursor / 人都能直接看到用到；脚手架 `scripts/init-specs.sh` 也在可见的 `scripts/`，跨 agent 通用。

> **模版骨架 = 精炼版（A）**：保留真实项目的章节结构，正文挖空为 `<填写：…>` 占位符 + flavor 固定常量（栈/危险区/约定）。丢一个 harness 文件夹即自带全部生成依赖，无外部依赖。

## 接入一个项目

```bash
# 1. 把本 harness 的内容放到项目根（.claude/.codex/CLAUDE.md/AGENTS.md/scripts/.cursor/.windsurfrules/spec-templates）
# 2. 加执行权限
chmod +x .claude/hooks/*.sh .codex/hooks/*.sh scripts/*.sh
# 3. 环境检查（项目模式会提示 docs/specs 是否就绪）
bash scripts/doctor.sh
# 4a. 若已有现成 specs → 放到项目根 docs/specs/
# 4b. 若没有 → 初始化（见下，按所用 agent 二选一）
```

**初始化分两步——脚手架（确定性）+ 填充（需 agent）：**

| 步骤 | Claude Code | Codex / Cursor / Windsurf / 人 |
|------|-------------|-------------------------------|
| ① 脚手架：探测 flavor、复制骨架到 `docs/specs/`、镜像放置目录级 AGENTS、生成 `dangerous-zones.txt`/`verify.cmd`/`verify.full.cmd` | 由 `/init-specs` 内部调用 | **手动**：`bash scripts/init-specs.sh` |
| ② 填充：探索真实代码、替换 `<填写：…>` 占位符、校准 `dangerous-zones.txt` | `/init-specs` 接着**自动完成** | **手动**：让 agent「按 `docs/specs/_RULE.md` 填充 docs/specs 占位符」 |

> ⚠️ **`scripts/init-specs.sh` 只做第①步（复制骨架），不填充内容**——产物全是 `<填写：…>` 占位符。只有 Claude Code 的 `/init-specs` 会接着自动做第②步探索+填充。其它 agent 需自己驱动填充。
> 生成物 frontmatter 标 `status: draft`，**人工复核后改 `active`**；复核可用 `bash scripts/doctor.sh --strict` 闸门（占位符/草稿未清则 fail）。

> 已有现成 specs 的项目（如 dc-platform / ecm-welfare）直接把整理好的 `docs/specs/` 放进项目根即可——脚手架与 `/init-specs` 检测到 `00_PROJECT_FACTS.md` 存在会自动跳过。

## specs 驱动机制

| 机制 | 来源 | 说明 |
|------|------|------|
| 危险区拦截 | `docs/specs/dangerous-zones.txt` | guard hook 逐行子串匹配；缺失时用内置通用兜底 |
| fast profile | `docs/specs/verify.cmd` | Stop hook 按顺序执行；通常是 typecheck/validate，一行一个命令 |
| full profile | `docs/specs/verify.full.cmd` | 可选；人工/CI 执行 fast 后再执行真实存在的 lint/build/test/smoke |
| PC 设计 token | `docs/token-specs/` | PC 页面色号、字号、主题覆盖以 Light.tokens.json / antd-vue-theme.ts 为准 |
| box-sizing 校验 | uni-app 项目门禁 | 仅当 `src/pages.json` 存在时启用 |
| 显式权限 | `docs/specs/13_AGENT_POLICY.md` | 统一使用 Allowed / Blocked / Ask First，避免把风险操作默认为已授权 |
| 按需查阅 | `docs/specs/00_PROJECT_FACTS.md` + `INDEX.md` | agent 先读事实与权限边界，再按需 grep 其余 |

## Hooks 一览

| Hook | 事件 | 做什么 |
|------|------|--------|
| doctor.sh | SessionStart | 环境 + 项目识别 + vue-tsc + docs/specs 是否就绪 |
| guard-dangerous-zones.sh | PreToolUse | 读 `dangerous-zones.txt` 拦截危险区写入（Claude Code）|
| block-dangerous-commands.sh | PreToolUse | 拦截 rm -rf / force push / 装包 / npx / curl |
| format-on-write.sh | PostToolUse | prettier（含 `.vue`）|
| check-box-sizing.sh | PostToolUse | padding 块需 `box-sizing`（仅 uni-app 项目）|
| check-large-file.sh | PostToolUse | 单 `.vue` > 500 行时提示按 `05_COMPONENT_PATTERNS.md`「拆分原则」拆分（advisory，不回滚）|
| record-permission-outcome.sh | PostToolUse | 按官方 `permission_mode` 记录已完成的 acceptEdits 编辑和 bypassPermissions 调用 |
| verify-before-stop.sh | Stop | fast profile（来自 `docs/specs/verify.cmd`）+ 改动摘要（Codex 版含格式化兜底 + 读 dangerous-zones.txt 危险区扫描）|

### 审计事件与反馈闭环

危险命令/危险区拦截、验证失败、doctor/verification readiness 状态，以及可观察的显式授权模式结果，会追加为 JSONL 到 `$(git rev-parse --git-path harness/events.jsonl)`。授权结果在真实 `PostToolUse` 生命周期记录：`acceptEdits` 下完成的编辑记为 approval，`bypassPermissions` 下完成的受支持工具调用记为 bypass；[Claude Code](https://code.claude.com/docs/en/hooks) 与 [Codex](https://developers.openai.com/codex/hooks) 的默认模式一次性人工批准都没有稳定的结果字段，因此不伪造记录。事件只有 `timestamp`、`adapter`、`event`、`category`、`decision`、`exit_status` 六个字段；不记录原始提示词、完整 shell 命令、文件路径/内容、token 或环境变量。审计文件位于 `.git/harness/`（linked worktree 使用对应 git path），不会污染仓库；记录失败也不会阻塞正常 Hook 决策。

每月按 `category + decision` 聚合一次事件，只处理重复出现且确有误用或漏拦截的模式：

1. 对照相关任务复核原因，不从审计记录反推或补采原始敏感数据。
2. 缺知识时更新 `docs/specs/`/playbook；缺提醒时加 advisory sensor；确认高风险且可判定时才加 blocking hook。
3. 对长期无命中、重复或误报高的规则降级或删除，并用 harness 测试固定调整后的预期。

### 验证档位与 baseline

```bash
# Stop hook 使用的快速检查
bash scripts/run-verification-profile.sh fast

# 人工或 CI 深度检查：先 fast，再执行可选 verify.full.cmd
bash scripts/run-verification-profile.sh full

# 保存命令/退出码基线（JSONL）；git-path 同时兼容普通仓库与 linked worktree
BASELINE_FILE=$(git rev-parse --git-path harness-verification.jsonl)
bash scripts/run-verification-profile.sh full --snapshot "$BASELINE_FILE"

# 历史失败只警告，新增失败才返回非零
bash scripts/run-verification-profile.sh full --compare "$BASELINE_FILE"
```

初始化器只使用 `package.json` 中真实存在的脚本或依赖。PC full 关注 lint/build/已有测试；uni-app full 关注 lint/build/已有平台 smoke，不会凭模板生成 `pnpm test`。

## Claude Code 与 Codex 差异

| | Claude Code | Codex |
|--|--|--|
| 入口 | CLAUDE.md | AGENTS.md + CLAUDE.md(fallback) |
| 配置 | .claude/settings.json | .codex/config.toml |
| Hooks 协议 | exit code | JSON stdout |
| Slash commands | ✅（含 /init-specs） | 不支持（手动按 spec-templates 规则生成）|
| 写入拦截 | ✅ | ✅ 覆盖 apply_patch/Edit/Write，Stop hook 再做完整变更兜底 |

## 迭代原则

**每次 agent 犯错，加固 harness（或补 specs），而不是改提示词。**
- 改了不该改的文件 → 往 `docs/specs/dangerous-zones.txt` 加路径
- 用了错误命名 → 对应目录 `AGENTS.md` 加规则
- 规格不准 → 改 `docs/specs/` 对应文档（跟代码同 PR 维护）
- 权限边界不清 → 更新 `docs/specs/13_AGENT_POLICY.md`，不要靠会话中的临时承诺

## Changelog

完整变更记录见 [`CHANGELOG.md`](./CHANGELOG.md)。当前版本 **v2.9**（在 v2.8.1 基础上：`02_ARCHITECTURE` 补 MVVM 通用分层基线、`05_COMPONENT_PATTERNS` 把拆分原则写成可判定规则、新增巨型文件门禁 `check-large-file.sh`、`/new-page`+`/review` 加拆分预判与组件粒度检查）。
