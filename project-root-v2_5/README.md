# Project Harness v2.4

将项目规格文档（specs）转化为可执行的 AI agent 约束（harness）。
同时支持 Claude Code 和 Codex CLI。

## 目录结构

```
project-root/
├── CLAUDE.md                  # Claude Code 入口（~40行硬规则）
├── AGENTS.md                  # 跨 agent 共享指令（Codex/Cursor/Windsurf 共读）
│
├── .claude/                   # ── Claude Code 专属 ──
│   ├── settings.json          #   hooks + permissions
│   ├── commands/              #   slash commands
│   │   ├── new-page.md        #     /new-page — 标准化新建页面
│   │   ├── debug.md           #     /debug — 结构化排障
│   │   ├── refactor.md        #     /refactor — 安全重构
│   │   ├── review.md          #     /review — 架构级代码审查
│   │   └── tech-solution.md   #     /tech-solution — 技术方案
│   └── hooks/
│       ├── guard-dangerous-zones.sh    # PreToolUse: 拦截危险区写入
│       ├── block-dangerous-commands.sh # PreToolUse: 拦截危险命令
│       ├── format-on-write.sh          # PostToolUse: 自动格式化
│       └── verify-before-stop.sh       # Stop: 类型检查 + 改动摘要
│
├── .codex/                    # ── Codex CLI 专属 ──
│   ├── config.toml            #   模型、审批策略、hooks
│   └── hooks/
│       ├── block-dangerous-commands.sh # JSON 协议版
│       ├── format-on-write.sh
│       └── verify-before-stop.sh       # 含格式化兜底 + 危险区扫描
│
├── scripts/
│   └── doctor.sh              # 环境预检（SessionStart hook + 可手动执行）
│
├── src/
│   ├── components/AGENTS.md   # 目录级约束：组件规范
│   ├── services/AGENTS.md     # 目录级约束：service 规范
│   └── shared/AGENTS.md       # 目录级约束：⚠️ 危险区
│
└── docs/specs/                # 原始规格文档（按需查阅，不预加载）
```

## 初始化

### 1. 环境检查

```bash
bash scripts/doctor.sh
```

### 2. 填写项目事实

打开 `CLAUDE.md`，把 `<例: ...>` 替换为真实信息。

### 3. 填写危险区路径

编辑以下两个文件中的 `DANGEROUS_PATTERNS`，填入你项目真正不能随便改的路径：
- `.claude/hooks/guard-dangerous-zones.sh`
- `.codex/hooks/verify-before-stop.sh`

### 4. 迁移 specs

把你原有的规格文档移入 `docs/specs/`。

### 5. 权限 + 启用

```bash
chmod +x .claude/hooks/*.sh .codex/hooks/*.sh scripts/*.sh
```

Codex 用户还需在 `~/.codex/config.toml` 中开启：

```toml
[features]
codex_hooks = true
```

## Hooks 一览

| Hook | 事件 | 做什么 |
|------|------|--------|
| doctor.sh | SessionStart | 检查 node/pnpm/jq/项目文件/harness 完整性 |
| guard-dangerous-zones.sh | PreToolUse | 拦截对危险区文件的写操作（Claude Code 专属） |
| block-dangerous-commands.sh | PreToolUse | 拦截 rm -rf / force push / 装包 / npx / curl |
| format-on-write.sh | PostToolUse | 写文件后自动 prettier |
| verify-before-stop.sh | Stop | 类型检查 + 改动摘要（Codex 版含格式化兜底 + 危险区扫描） |

## Claude Code 与 Codex 差异

| 机制 | Claude Code | Codex CLI |
|------|------------|-----------|
| 指令入口 | CLAUDE.md | AGENTS.md + CLAUDE.md（fallback） |
| 配置 | .claude/settings.json | .codex/config.toml |
| Hooks 协议 | exit code（0=通过, 2=阻止） | JSON stdout |
| Slash commands | .claude/commands/*.md | 不支持 |
| 文件写入拦截 | ✅ Write/Edit/MultiEdit | ⚠️ apply_patch 暂不触发（Stop hook 兜底） |

## 日常使用

```bash
# Claude Code
claude
/new-page 用户列表页
/debug 表格排序点击无效
/refactor 将 userService 拆分
/review src/pages/UserList.tsx
/tech-solution 新增审批流模块

# Codex CLI
codex "新增用户列表页"
codex "debug: 表格排序无效"
```

## 迭代原则

**每次 agent 犯错，加固 harness，而不是改提示词。**

- Agent 改了不该改的文件 → `guard-dangerous-zones.sh` 加路径
- Agent 用了错误的命名风格 → 对应目录的 `AGENTS.md` 加规则
- Agent 忘了跑测试 → `verify-before-stop.sh` 加检查项
- Agent 反复犯同一类错 → 写一个新的 slash command 固化流程

## 常见接入失败原因

**Hooks 不生效（静默跳过）**
最常见的原因是 hook 脚本没有执行权限。运行 `chmod +x .claude/hooks/*.sh .codex/hooks/*.sh scripts/*.sh`。Codex 用户还需确认 `~/.codex/config.toml` 中 `[features]` 下 `codex_hooks = true` 已开启，否则所有 hooks 会被静默忽略。

**jq: command not found**
所有 hooks 依赖 jq 解析输入 JSON。macOS 用 `brew install jq`，Ubuntu 用 `apt install jq`。运行 `bash scripts/doctor.sh` 可以一次性检查所有依赖。

**prettier / tsc 找不到**
hooks 使用 `pnpm exec prettier` 和 `pnpm exec tsc`，需要这两个包在项目 devDependencies 中。如果是新项目，先 `pnpm add -D prettier typescript`。

**Claude Code hooks 自我拦截**
如果你在 deny 列表中禁了 `Bash(npx *)`，但 hooks 里又用 `npx` 执行命令，会导致 hooks 被自己的规则拦截。v2.4 已统一为 `pnpm exec`，并在 allow 列表中放行了 `Bash(pnpm exec*)`。

**Codex 危险区文件被绕过**
Codex 的 apply_patch 工具目前不触发 PreToolUse hooks（上游 issue openai/codex#16732）。v2.4 在 Codex Stop hook 中增加了兜底：结束前扫描 `git diff` 检查是否有危险区文件被修改，并对所有改动文件补跑 prettier。

**CLAUDE.md 中的占位符未填写**
如果 CLAUDE.md 还留着 `<例: ...>` 占位符，agent 会把示例当成项目事实。接入后第一件事就是把所有占位符换成真实值。

## Changelog

### v2.5
- `.codex/config.toml` 删除写死的 `model = "o4-mini"`，模型选择留给个人 `~/.codex/config.toml`
- slash commands 中所有写死的 `pnpm test` / `pnpm tsc --noEmit` 改为引用 CLAUDE.md 中声明的命令
- 分工明确：hooks（机制层）写死命令保证确定性，commands（指令层）引用 CLAUDE.md 保证灵活性

### v2.4
- 删除构建残留目录 `{.claude/`
- 所有 hooks 中 `npx` → `pnpm exec`，settings.json allow 列表增加 `pnpm exec`
- Codex hooks 使用 `printf` + 变量消毒替代手拼 JSON，避免特殊字符导致 JSON 破损
- Codex Stop hook 新增格式化兜底（对所有改动文件补跑 prettier）
- README 新增「常见接入失败原因」

### v2.3
- doctor.sh 移至 `scripts/`，同时作为 SessionStart hook 自动执行
- 新增 `/review` slash command
- AGENTS.md 去除「标准任务收尾模板」（改由 Stop hook 自动输出 git diff）
- Codex Stop hook 新增危险区兜底扫描
- 删除 `docs/harness/` 目录

### v2.0
- 从 7782 行 specs 体系重构为 harness 配置
- 新增 4 个 hooks + 4 个 slash commands
- 支持 Claude Code + Codex CLI 双 agent
