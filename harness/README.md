# Project Harness（通用 · specs 外置 + 自动生成）

**版本：v2.9**　·　完整变更见 [`CHANGELOG.md`](./CHANGELOG.md)

把项目规格（specs）转化为可执行的 AI agent 约束（harness）。支持 Claude Code / Codex / Cursor / Windsurf。

**核心理念：harness 不内置任何项目的真实 specs，只带「生成规则」（`spec-templates/`）。**
- specs 由每个项目在自己根目录的 `docs/specs/` 维护。
- **是否「已初始化」一律以 `docs/specs/00_PROJECT_FACTS.md` 是否存在为准**（不看 `docs/specs/` 目录是否存在——空目录不算已初始化）。
  - 未初始化 → 见下方「初始化」；已初始化 → agent 先读 `00_PROJECT_FACTS.md` + `INDEX.md`，其余按需查阅。
- 危险区等机制由 specs **驱动**（hook 读 `docs/specs/dangerous-zones.txt`、类型检查读 `docs/specs/verify.cmd`），harness 本体保持通用、可移植。
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
│   └── hooks/                 #   guard（读 dangerous-zones.txt）/ block / format(.vue) / check-box-sizing(uni-app) / check-large-file(.vue>500行) / verify(vue-tsc)
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
| ① 脚手架：探测 flavor、复制骨架到 `docs/specs/`、镜像放置目录级 AGENTS、生成 `dangerous-zones.txt`/`verify.cmd` | 由 `/init-specs` 内部调用 | **手动**：`bash scripts/init-specs.sh` |
| ② 填充：探索真实代码、替换 `<填写：…>` 占位符、校准 `dangerous-zones.txt` | `/init-specs` 接着**自动完成** | **手动**：让 agent「按 `docs/specs/_RULE.md` 填充 docs/specs 占位符」 |

> ⚠️ **`scripts/init-specs.sh` 只做第①步（复制骨架），不填充内容**——产物全是 `<填写：…>` 占位符。只有 Claude Code 的 `/init-specs` 会接着自动做第②步探索+填充。其它 agent 需自己驱动填充。
> 生成物 frontmatter 标 `status: draft`，**人工复核后改 `active`**；复核可用 `bash scripts/doctor.sh --strict` 闸门（占位符/草稿未清则 fail）。

> 已有现成 specs 的项目（如 dc-platform / ecm-welfare）直接把整理好的 `docs/specs/` 放进项目根即可——脚手架与 `/init-specs` 检测到 `00_PROJECT_FACTS.md` 存在会自动跳过。

## specs 驱动机制

| 机制 | 来源 | 说明 |
|------|------|------|
| 危险区拦截 | `docs/specs/dangerous-zones.txt` | guard hook 逐行子串匹配；缺失时用内置通用兜底 |
| 类型检查命令 | `docs/specs/verify.cmd` | verify hook 读它；缺失时探测 package.json 脚本（lint:type/validate/…），再兜底 `pnpm exec vue-tsc --noEmit` |
| PC 设计 token | `docs/token-specs/` | PC 页面色号、字号、主题覆盖以 Light.tokens.json / antd-vue-theme.ts 为准 |
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
| check-large-file.sh | PostToolUse | 单 `.vue` > 500 行时提示按 `05_COMPONENT_PATTERNS.md`「拆分原则」拆分（advisory，不回滚）|
| verify-before-stop.sh | Stop | 类型检查（命令来自 `docs/specs/verify.cmd`，缺失则探测脚本/兜底 vue-tsc）+ 改动摘要（Codex 版含格式化兜底 + 读 dangerous-zones.txt 危险区扫描）|

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

完整变更记录见 [`CHANGELOG.md`](./CHANGELOG.md)。当前版本 **v2.9**（在 v2.8.1 基础上：`02_ARCHITECTURE` 补 MVVM 通用分层基线、`05_COMPONENT_PATTERNS` 把拆分原则写成可判定规则、新增巨型文件门禁 `check-large-file.sh`、`/new-page`+`/review` 加拆分预判与组件粒度检查）。
