角色：你是项目规格初始化工程师。目标是把 harness 自带的**模版骨架**落到项目根 `docs/specs/`，再按真实代码填充，产出初版规格作为后续所有任务的事实来源。

## 前置判断（以三态文件为准，不看目录）

1. `missing`：`docs/specs/00_PROJECT_FACTS.md` 不存在（即使有空的 `docs/specs/` 目录）→ 运行脚手架。
2. `draft`：facts 存在但有占位符、非 `active` 状态或尚未复核 → 不运行会覆盖的脚手架，按 `docs/specs/_RULE.md` 继续填充并人工复核。
3. `active`：facts 存在、无占位符且文档状态均为 `active` → 跳过初始化并报告；不得覆盖现有项目事实。

## 第一步：跑脚手架脚本（确定性部分）

4. 仅在 `missing` 状态运行 `bash scripts/init-specs.sh`（自动探测 flavor；可 `--flavor pc|mini` 强制）。它会：
   - 探测项目类型（PC 微前端 / uni-app 多端）
   - 把对应 `spec-templates/<flavor>/` 的骨架复制到 `docs/specs/`（00..12、`13_AGENT_POLICY` + INDEX + dangerous-zones.txt + 组件库索引 + examples + skills-reference）
   - 把 `AGENTS/` 下的目录级 AGENTS.md **按镜像路径**放到项目真实目录（如 `apps/micro-main/`、`src/utils/`）
   - 放一份 `docs/specs/_RULE.md` 作为填充指引
   > 若脚本判不出 flavor，自己按上述特征判断后用 `--flavor` 重跑。

## 第二步：探索真实代码，填充占位符

5. 读 `docs/specs/_RULE.md` 与 `spec-templates/SCHEMA.md`，用 `head`/`grep`（不要 `cat` 全文）从真实代码取证：
   - `package.json`（name/scripts/依赖/包管理器）、`pnpm-workspace.yaml`、`tsconfig*`、`vite.config*`、`pages.json`/`manifest.json`
   - 入口与基础设施：`main.ts`、`App.vue`、请求封装、认证、路由
   - 目录结构、端口、env/baseURL、UI 库注册
   - PC 组件库：从 lockfile/overrides 取实际锁定版本，检查安装包类型声明或导出入口，并 grep 项目真实调用；只记录当前版本已验证的组件能力
   - 页面示例：仅从项目中真实存在的列表、新建/编辑、详情页面提炼；按页面类型组织并标明可复用模式与业务特例
6. 逐份替换 `docs/specs/` 里的 `<填写：…>` 占位符；删除不适用章节，补真实情况。
7. **务必校准 `docs/specs/dangerous-zones.txt`**（hooks 危险区来源）；并核对 `docs/specs/verify.cmd`（fast）与 `docs/specs/verify.full.cmd`（可选 full），删除不存在的命令，如 monorepo 需补 filter。
8. **真实性纪律**：实现事实只写代码、配置或运行证据确认的内容，拿不准写 `// TODO: 待确认` 留空，**禁止编造**。用户目标和业务决策按知识契约保留稳定编号，不用目标改写实现事实；`status` 暂留 `draft`，`last_verified` 填今天。

## 收尾

9. 删除 `docs/specs/_RULE.md`；运行 `bash scripts/doctor.sh` 确认 specs 就绪。
10. 输出生成清单 + 每份一句话总结 + 所有 `待确认` 项请人工复核；复核后把各文档 `status` 改 `active`。`active` 只表示实现事实复核，不代表用户业务验收。

初始化完成后按 [docs/harness/verification.md](../../docs/harness/verification.md) 留下命令、环境和未验证范围；同一问题连续两轮修复仍失败才升级。

可选范围/侧重：$ARGUMENTS
