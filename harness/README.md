# Project Harness（通用 · specs 外置 + 自动生成）

**Harness 2.0.0**　·　基于 v2.9 机制演进　·　既有 v2.9 历史记录保持不变　·　完整变更见 [`CHANGELOG.md`](./CHANGELOG.md)

把项目规格（specs）转化为可执行的 AI agent 约束（harness）。支持 Claude Code / Codex / Cursor / Windsurf。

从问题出发的静态工具导航见 [`MAP.md`](./MAP.md)；接入项目后由根 `PROJECT_MAP.md` 登记实际生成的资料域。通用知识与验收规则分别见 [`docs/harness/knowledge.md`](./docs/harness/knowledge.md) 和 [`docs/harness/verification.md`](./docs/harness/verification.md)。

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
├── MAP.md                    # 总导航：需求、架构、开发、证据、验收、发布入口
├── VERSION                   # Harness 版本：2.0.0
├── docs/harness/              # 通用知识与验收契约（不含业务项目事实）
│   ├── knowledge.md
│   └── verification.md
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
│   ├── record-permission-outcome.sh # PostToolUse 可观察授权模式审计
│   └── init-project-knowledge.sh # 按需生成 docs/specs/ 之外的资料 draft
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
├── project-templates/         # 👈 需求/实现/设计/证据/经验资料模板（显式生成 draft）
│   ├── MANIFEST.tsv           #     三列 Tab 清单：domain / path / kind
│   └── README.md              #     生成、状态和引用链规则
├── token-templates/           # PC 设计 token 模板（初始化时复制到 docs/token-specs/）
│   └── pc/
│       ├── Light.tokens.json
│       ├── antd-vue-theme.ts
│       └── README.md
└── docs/specs/                # ← 由 /init-specs（或 scripts/init-specs.sh）复制骨架+填充生成（不随 harness 分发）
└── docs/token-specs/          # ← PC flavor 初始化时生成，色号/字号/主题 token 以此为准
```

资料模板另见 `project-templates/`：它按需提供需求、实现、设计、环境证据、验收和可选经验/badcase 的 draft 骨架，不复制业务事实。机器清单为 `project-templates/MANIFEST.tsv`；模板与目标生成物的规则见 `project-templates/README.md`。

> 模版放在**可见的根目录 `spec-templates/`**（不藏在 `.claude/` 下），Codex / Cursor / 人都能直接看到用到；脚手架 `scripts/init-specs.sh` 也在可见的 `scripts/`，跨 agent 通用。

> **模版骨架 = 精炼版（A）**：保留真实项目的章节结构，正文挖空为 `<填写：…>` 占位符 + flavor 固定常量（栈/危险区/约定）。丢一个 harness 文件夹即自带全部生成依赖，无外部依赖。

## 版本、分发与升级

当前发布版本由根 `VERSION` 固定为 `2.0.0`。归档分发只以 `distribution/MANIFEST.txt` 列出的工具资产为准，构建入口为：

```bash
# DIR 必须位于 Harness 源码树之外（例如 /tmp/harness-dist）
bash scripts/package-harness.sh --output DIR
```

构建产物为 `project-harness-2.0.0.tar.gz` 及对应 `.sha256`；构建允许使用系统 Python 3 标准库，安装和运行 Harness 不新增业务项目依赖。升级前先对照 `distribution/MANIFEST.txt` 和归档清单，备份并保留目标项目根 `PROJECT_MAP.md`、已生成领域资料、`docs/specs/`、`docs/token-specs/` 与自定义入口；升级顺序必须先在源码树外 staging 解包并完成旧 MAP 登记迁移，再覆盖静态 MAP 和工具资产，不得盲目覆盖用户内容。长期效率、维护收益和实际填写率需要接入项目试点验证，不作为 2.0.0 归档已证明的业务结果。

### 升级已有接入项目

已有项目必须先迁移旧根 `MAP.md` 的生成登记，再覆盖静态 MAP 和 Harness 工具资产。新包先解压到源码树外的 staging 目录；备份 `PROJECT_MAP.md`、旧 `MAP.md`、已生成领域、`docs/specs/`、`docs/token-specs/` 和自定义入口。旧 `MAP.md` 仍在项目根时，按旧项目实际已经生成的 domain 分别调用 staging 中的新生成器（下面以 `requirements` 为例）：

```bash
# 新包位于项目源码树之外；staging 也必须在源码树之外
mkdir -p /tmp/project-harness-2.0.0-staging
tar -xzf project-harness-2.0.0.tar.gz -C /tmp/project-harness-2.0.0-staging

# 旧 MAP.md 尚未覆盖时，先迁移旧项目实际已有的 domain
project_target=$(cd /path/to/project && pwd -P)
bash /tmp/project-harness-2.0.0-staging/project-harness-2.0.0/scripts/init-project-knowledge.sh \
  --target "$project_target" --domain requirements
```

对旧项目已经存在的其他 domain 重复调用对应 `--domain`（不要为补齐结构使用 `--domain all`，也不要凭空生成未使用的 domain）；需要模块或案例时只带上旧项目实际存在且已核对的 `--module`/`--case`。核对 `PROJECT_MAP.md` 已收集旧 MAP 标记块中的本地条目并去重后，才用 staging 归档覆盖静态 `MAP.md`、脚本和其他允许替换的工具资产；已有自定义入口差异逐项合并，不盲目覆盖。迁移只保留登记，不删除旧 MAP 正文或用户资料。

## 接入一个项目

```bash
# 1. 新接入直接使用分发归档中的清单资产；升级已有项目必须先按上方“升级已有接入项目”迁移旧 MAP，再覆盖工具资产（保留用户 PROJECT_MAP.md、领域资料、specs/token 与自定义入口）
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

> 分发 Harness 时必须同时包含 `MAP.md`、`docs/harness/`、`project-templates/` 和对应脚本；它们是通用导航/契约，不承载真实业务 specs。初始化器创建的用户索引固定为项目根 `PROJECT_MAP.md`，已有 `docs/specs/` 路径保持不变。

> 初始化按三态处理：`missing` 执行脚手架；`draft` 时脚本不覆盖并退出，Claude `/init-specs` 继续填充；`active` 时脚本与 `/init-specs` 均跳过。仅存在空的 `docs/specs/` 目录不算已初始化；已有现成 specs 的项目可直接放入项目根后按状态复核。

### 按需生成项目资料

显式调用 `scripts/init-project-knowledge.sh` 可独立生成资料 domain；它写入 `docs/specs/` 之外的 draft 文件，保留已有资料，不强制迁移目录：

```bash
bash scripts/init-project-knowledge.sh --domain harness
bash scripts/init-project-knowledge.sh --domain requirements --module orders
bash scripts/init-project-knowledge.sh --domain design
bash scripts/init-project-knowledge.sh --domain docs
bash scripts/init-project-knowledge.sh --domain experience --case keyboard-focus
bash scripts/init-project-knowledge.sh --domain all --dry-run
```

初始化命令不覆盖既有资料；在上述升级顺序中，旧根 `MAP.md` 生成标记内的本地条目会在预检通过后迁移到 `PROJECT_MAP.md`，其余已有内容保持不变。`--module` 和 `--case` 只在显式提供安全标识时实例化；不带参数只展示用法，`--dry-run` 不创建文件。既有前端 specs、token、Hook 和公共验收规则仍各自维护唯一来源，资料模板只建立需求 ID → 模块 → 实现 → 用例 → 偏差 → 证据的引用链。

如果目标项目旧版根 `MAP.md` 含有 `<!-- init-project-knowledge generated entries -->` 标记，初始化器会在预检通过后把其中仍存在的本地链接去重登记到 `PROJECT_MAP.md`；根 `MAP.md` 的正文和原有登记不删除、不改写。标记块格式或目标路径不合法时整次初始化提前失败；重复运行只补缺失登记，不覆盖已有项目资料。

## specs 驱动机制

| 机制 | 来源 | 说明 |
|------|------|------|
| 危险区拦截 | `docs/specs/dangerous-zones.txt` | guard hook 逐行子串匹配；缺失时用内置通用兜底 |
| fast profile | `docs/specs/verify.cmd` | Stop hook 按顺序执行；通常是 typecheck/validate，一行一个命令 |
| full profile | `docs/specs/verify.full.cmd` | 可选；人工/CI 执行 fast 后再执行真实存在的 lint/build/test/smoke |
| PC 设计 token | `docs/token-specs/`（目标项目实际提供时） | 以目标项目已生成并核对的 token/主题来源为准；未提供时记录 `none`/`unverified`，不假定 `Light.tokens.json` 或主题文件存在 |
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

完整变更记录见 [`CHANGELOG.md`](./CHANGELOG.md)。当前为 **Harness 2.0.0**；既有 v2.9 历史基线改动仍见变更记录。
