# Project Harness v2.8（通用 · specs 外置 + 自动生成）

把项目规格（specs）转化为可执行的 AI agent 约束（harness）。支持 Claude Code / Codex / Cursor / Windsurf。

**v2.8 的核心变化：harness 不再内置任何项目的 specs，只保留「生成规则」。**
- specs 由每个项目在自己根目录的 `docs/specs/` 维护。
- 接入新项目时：若 `docs/specs/` **不存在** → 运行 `/init-specs`，agent 按 `spec-templates/` 规则**探索整个项目自动生成初版**；若**已存在** → 直接复用其内容。
- 危险区等机制由 specs **驱动**（hook 读 `docs/specs/dangerous-zones.txt`），harness 本体保持通用、可移植。

## 目录布局（harness 内容直接放项目根）

```
你的项目根/
├── CLAUDE.md                 # 通用：角色 + 原则 + "先读 docs/specs/，无则 /init-specs"
├── AGENTS.md                 # 跨 agent 共享指令
├── .cursor/rules/ .windsurfrules
├── .claude/                   # Claude Code 专属
│   ├── settings.json
│   ├── commands/              #   /init-specs /new-page /debug /refactor /review /tech-solution
│   └── hooks/                 #   guard（读 dangerous-zones.txt）/ block / format(.vue) / check-box-sizing(uni-app) / verify(vue-tsc)
├── .codex/{config.toml, hooks/}   # Codex 专属
├── scripts/
│   ├── doctor.sh              # 自检/项目双模式：检测环境 + docs/specs 是否就绪
│   └── init-specs.sh          # 👈 跨 agent 脚手架：复制骨架→docs/specs/ + 放置 AGENTS
├── spec-templates/            # 👈 可见、agent 中立的模版骨架（生成 docs/specs 的全部依赖，随 harness 走）
│   ├── SCHEMA.md              #   通用规则：要哪些文件、各写什么、dangerous-zones.txt 格式
│   ├── pc-microapp/           #   PC 微前端 flavor —— 全套骨架（提炼自 dc-platform）
│   │   ├── RULE.md            #     探索+填充说明
│   │   ├── 00_PROJECT_FACTS.md … 12_TROUBLESHOOTING.md  INDEX.md  dangerous-zones.txt
│   │   ├── dcgj-components/  examples/  skills-reference/
│   │   └── AGENTS/           #     apps/ · apps/micro-main/ · packages/ 目录级 AGENTS 模版（镜像放置）
│   └── miniprogram-uniapp/    #   uni-app 多端 flavor —— 全套骨架（提炼自 ecm-welfare）
│       ├── RULE.md
│       ├── 00_PROJECT_FACTS.md … 12  INDEX.md  dangerous-zones.txt
│       ├── uview-components/  examples/  skills-reference/
│       └── AGENTS/           #     src/api · src/components · src/composables · src/utils
└── docs/specs/                # ← 由 /init-specs（或 scripts/init-specs.sh）复制骨架+填充生成（不随 harness 分发）
```

> 模版放在**可见的根目录 `spec-templates/`**（不藏在 `.claude/` 下），Codex / Cursor / 人都能直接看到用到；脚手架 `scripts/init-specs.sh` 也在可见的 `scripts/`，跨 agent 通用。

> **模版骨架 = 精炼版（A）**：保留真实项目的章节结构，正文挖空为 `<填写：…>` 占位符 + flavor 固定常量（栈/危险区/约定）。`/init-specs` 把骨架复制进 `docs/specs/` 再按真实代码填充。丢一个 harness-v2.8 文件夹即自带全部生成依赖，无外部依赖。

## 接入一个项目

```bash
# 1. 把本 harness 的内容放到项目根（.claude/.codex/CLAUDE.md/AGENTS.md/scripts/.cursor/.windsurfrules）
# 2. 加执行权限
chmod +x .claude/hooks/*.sh .codex/hooks/*.sh scripts/*.sh
# 3. 环境检查（会提示 docs/specs 是否存在）
bash scripts/doctor.sh
# 4a. 若已有现成 specs → 放到项目根 docs/specs/（见 ready-specs 包）
# 4b. 若没有 → 在 Claude Code 中：
claude
/init-specs
```

`/init-specs` 会：判断项目类型（PC 微前端 / uni-app 多端）→ 探索代码 → 按对应 flavor 规则生成 `docs/specs/`（含 `00_PROJECT_FACTS.md`、`INDEX.md`、`02..12`、`dangerous-zones.txt`、关键目录的 `AGENTS.md`）。生成物标 `status: draft`，请人工复核。

> 已有现成 specs 的两个项目（dc-platform / ecm-welfare）见随附 **ready-specs** 包，直接把对应目录放进各自项目根即可，`/init-specs` 会识别已存在并跳过。

## specs 驱动机制

| 机制 | 来源 | 说明 |
|------|------|------|
| 危险区拦截 | `docs/specs/dangerous-zones.txt` | guard hook 逐行子串匹配；缺失时用内置通用兜底 |
| 类型检查 | `vue-tsc --noEmit` | 两类项目都是 Vue，用 vue-tsc（非 tsc）|
| box-sizing 校验 | uni-app 项目门禁 | 仅当 `src/pages.json` 存在时启用 |
| 按需查阅 | `docs/specs/00_PROJECT_FACTS.md` + `INDEX.md` | agent 先读事实，再按需 grep 其余 |

## Hooks 一览

| Hook | 事件 | 做什么 |
|------|------|--------|
| doctor.sh | SessionStart | 环境 + 项目识别 + vue-tsc + docs/specs 是否就绪 |
| guard-dangerous-zones.sh | PreToolUse | 读 `dangerous-zones.txt` 拦截危险区写入（Claude Code）|
| block-dangerous-commands.sh | PreToolUse | 拦截 rm -rf / force push / 装包 / npx / curl |
| format-on-write.sh | PostToolUse | prettier（含 `.vue`）|
| check-box-sizing.sh | PostToolUse | padding 块需 `box-sizing`（仅 uni-app 项目）|
| verify-before-stop.sh | Stop | `vue-tsc` + 改动摘要（Codex 版含格式化兜底 + 读 dangerous-zones.txt 危险区扫描）|

## Claude Code 与 Codex 差异

| | Claude Code | Codex |
|--|--|--|
| 入口 | CLAUDE.md | AGENTS.md + CLAUDE.md(fallback) |
| 配置 | .claude/settings.json | .codex/config.toml |
| Hooks 协议 | exit code | JSON stdout |
| Slash commands | ✅（含 /init-specs） | 不支持（手动按 spec-templates 规则生成）|
| 写入拦截 | ✅ | ⚠️ apply_patch 不触发，Stop hook 兜底 |

## 迭代原则

**每次 agent 犯错，加固 harness（或补 specs），而不是改提示词。**
- 改了不该改的文件 → 往 `docs/specs/dangerous-zones.txt` 加路径
- 用了错误命名 → 对应目录 `AGENTS.md` 加规则
- 规格不准 → 改 `docs/specs/` 对应文档（跟代码同 PR 维护）

## Changelog

### v2.8
- **specs 外置 + 自带模版骨架**：harness 不内置真实 specs，改为 `spec-templates/`，含 SCHEMA + PC/uni-app 两套**全覆盖骨架**（00..12 + INDEX + dangerous-zones.txt + 组件库索引 + examples + skills-reference + 目录级 AGENTS），A 精炼版（结构保留、正文占位）
- 新增 `/init-specs`：选 flavor → 复制骨架到 `docs/specs/` → 探索真实代码填充（含校准 `dangerous-zones.txt` 与镜像放置目录级 AGENTS）
- 危险区改为 specs 驱动：guard / codex verify 读 `docs/specs/dangerous-zones.txt`，缺失时通用兜底
- doctor.sh：检测 `docs/specs` 缺失 → 提示运行 `/init-specs`
- CLAUDE.md/AGENTS.md/commands 通用化（不再内联具体项目事实）
- 两套现成 specs（dc-platform / ecm-welfare）移出 harness，单独以 ready-specs 包分发

### v2.7（统一版）
- 整合 dc-platform + ecm-welfare 两个不同栈 Vue3 项目；hooks 项目自适应（vue-tsc / box-sizing / 危险区并集）

### v2.6 / v2.5 / v2.4 / v2.3 / v2.0
- 角色/上下文纪律/失败熔断；commands 引用 CLAUDE.md；npx→pnpm exec、JSON 消毒、格式化兜底；doctor SessionStart、/review；从 specs 体系重构为 harness。
