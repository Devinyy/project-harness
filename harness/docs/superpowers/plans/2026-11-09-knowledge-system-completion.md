# Harness 2.0 资料体系补全实施计划

> **For agentic workers:** 使用 executing-plans 在当前会话执行。用户已授权“继续补全”，无需再次确认执行方式。两名文件归属明确的 Luna 执行者分别负责资料与工具，自行完成自检和普通修复，随后独立 QA。

**Goal:** 将前一轮已建立的总导航与通用规则，补成包含完整领域模板、按需生成、索引关联和验证的可复用资料体系。

**Architecture:** 新增 project-templates/，镜像用户期望的 harness/、requirements/、design/、docs/，附带可选经验与 badcase 模板。显式调用初始化器才向业务项目生成 draft 骨架，不在通用 Harness 内伪造真实业务记录。现有 docs/specs/、token 模板、公共知识与 QA 规则继续复用。

**Tech Stack:** Markdown、Bash、jq、Git、既有 shell 契约测试；生产脚本不新增运行依赖，不调用外部服务。

## 工作区与所有权

- 工作目录：/Users/zhangxiang/devin-harness/harness；Git 根：/Users/zhangxiang/devin-harness；分支：codex/harness-2.0。
- 当前工作区已有上一轮未提交的 2.0 成果，属于用户授权工作，必须增量保留，不能还原到 HEAD。不要提交、推送、合并或切换分支。
- 主 Agent 拥有本计划。资料执行者拥有 project-templates/、docs/harness/（含图示）、根 MAP/AGENTS、README/CHANGELOG 和其他现有文档入口；工具执行者拥有 scripts/init-project-knowledge.sh、scripts/doctor.sh、tests/harness/test-project-knowledge.sh 及必要的测试 fixture 适配。两者按下方固定接口独立推进，不写同一文件。不是独占仓库，不回滚其他人的改动。
- 不涉及前端业务代码，无需加载前端实现专项；不将截图中的项目专有代码/业务内容当作本仓库事实。

## 模板与生成器的固定接口

- project-templates/MANIFEST.tsv 为三列、Tab 分隔：domain、path、kind；允许 # 注释，无表头；domain 为 harness/requirements/design/docs/experience，kind 为 static/module/case。
- path 同时是 project-templates/ 下的源路径与目标相对路径；module 源固定 requirements/modules/_module.md，目标为 requirements/modules/<module>.md；case 源固定 badcase/_case.md，目标为 badcase/<case>.md。
- static 按原路径生成；module/case 只在显式提供对应参数时实例化，绝不生成 _module.md 或 _case.md 作为业务记录。
- 允许的渲染符号：{{ROOT}} 为相对目标项目根的路径（根层为 ./，下层为 ../ 重复）；{{MODULE}}、{{CASE}} 为校验后的标识；{{DATE}} 为生成时 UTC 日期。其余内容不执行。
- 顶层 status: template 在生成物中改为 status: draft；模板本身不改。domain all 选择五组静态模板，实例化仍受 module/case 参数控制。
- 域内固定静态文件可直接用相对 Markdown 链接；可选跨域文件、前端specs/token和通用规则用明确的项目根 code 路径说明，避免部分生成时产生坏链接。
- 根和局部MAP通过追加去重登记维护，保留原文；模块登记到 requirements/modules/MAP.md，案例登记到 badcase/MAP.md。生成器负责动态登记，模板不硬编码不存在的模块或案例。

## Task 1：补全可复用模板包

建立 project-templates/README.md 和机器可读清单，完整提供以下模板。模板标明 status: template，并说明信息来源、使用条件与维护时机，不编造 API、模块、环境或验收结果。

- harness/MAP.md、adr.md、impl.md、naming.md、test-spec.md、deviations.md。
- harness/scenes/MAP.md、implement.md、verify.md。verify 只引用 docs/harness/verification.md 的唯一公共规则，不复制触发条件；implement 规定目标→范围→实现→自检→QA→记录更新，引用既有专项 playbook。
- requirements/MAP.md、overview.md、confirmed-rules.md、modules/MAP.md，以及按指定模块名实例化的模块模板。
- design/MAP.md、tokens.md、interaction.md。tokens 优先引用已有 docs/token-specs/ 与前端 UI 指南，不复制 token 值；interaction 记录已确认交互与状态约束。
- docs/MAP.md、environment.md、api-integration.md、backend-evidence.md、release-evidence.md。
- 可选 experience 领域：experience/MAP.md、experience/aibrain/MAP.md、preflight.md、retrospective.md、keyboard-events.md；badcase/MAP.md 与按案例名实例化的案例模板。经验库归入 experience/，根 MAP 统一登记经验域与 badcase 入口。
- 图示：harness/diagrams/MAP.md 和维护说明；保存反映本仓库当前实际结构与导航的 Mermaid 图到 docs/harness/diagrams/，从现有总 MAP 可达。不要生成虚假的业务系统架构。

内容要求：

- ADR 包含编号、来源/日期、状态、背景、备选、决策、影响和替代关系；impl 只记录当前实现并引用前端 specs。
- naming 记录跨领域术语与改名同步，前端细节引用04；test-spec 包含稳定用例编号、目标规则、前提、操作、预期和覆盖边界，实际结果另行留证。
- deviations 包含目标编号、当前证据、影响、状态、处理角色、下一步、修复与关闭证据；关闭不删历史。
- requirements 的确认状态、实现状态、验收结果分开，目标只维护一份；模块文档引用规则ID、实现位置、用例ID和差距ID，建立可追踪链。
- 环境与证据记录包含仓库/提交/环境/核对时间/来源/实际结果/未验证范围；生产状态不能由本地源码推定。
- 模板预览中的未实例化链接明确标记；生成后的所有 Markdown 链接按所在文件目录解析，不能引用缺失的可选文件。

## Task 2：显式、增量、可重复的按需生成

新建 scripts/init-project-knowledge.sh，建议接口：

```bash
bash scripts/init-project-knowledge.sh --domain requirements --module orders
bash scripts/init-project-knowledge.sh --domain harness
bash scripts/init-project-knowledge.sh --domain design
bash scripts/init-project-knowledge.sh --domain docs
bash scripts/init-project-knowledge.sh --domain experience --case keyboard-focus
bash scripts/init-project-knowledge.sh --domain all --dry-run
```

- 支持上述六种 domain；不带参数只展示用法，不默认生成全部目录；--dry-run 不产生任何文件/目录修改。
- 资源从脚本自身的分发根定位，产物写到调用工作目录。目标工作目录不是一定要有 package.json，不能假设框架。
- --module/--case 的名称验证要拒绝绝对路径、斜杠、.. 与控制字符，避免目录穿越；脚本不 eval 用户参数。
- 先验证所需源模板和目标路径安全性，再写入；已有文件原样保留，重复运行幂等，没有隐式覆盖/force。
- 生成记录骨架 status: draft，不能声称 confirmed、observed 或验收通过；只按用户实际证据填充后再改状态。
- 明确 --module/--case 依赖与用法。模块/案例每次创建后登记最近 MAP；已有自定义 MAP 只增补所需索引，不能覆盖原内容或重复登记。
- 将已生成的领域 MAP 登记到根 MAP 的增量区域，保留用户原文；没有根 MAP 时生成最小、真实有效的导航。
- 领域生成可独立运行，也支持 all。跨领域依赖缺失时使用明确的 code 路径/状态说明，不能产生不可解析 Markdown 链接。
- 初始化器不改 scripts/init-specs.sh、scripts/lib/specs-state.sh、Hooks 或真实用户前端 specs；显式创建的领域草稿均在 docs/specs/ 之外。
- 模板源与生成物之间允许必要的轻量占位符渲染，替换范围必须确定，不执行模板中的代码。

## Task 3：接入当前导航、维护规则与分发

- 更新 MAP.md、docs/harness/knowledge.md、README.md、CHANGELOG.md，加入模板预览、生成命令、逐领域入口、更新触发和追溯链说明。
- 更新知识规则，明确“显式初始化创建 draft 骨架”与“不无条件生成空业务事实”兼容；既有项目路径可以沿用，不强制搬迁。
- 根 AGENTS 只增加必要短路由，保持现有行数预算；其他 Agent 入口按实际需要引用，不重复正文。
- scripts/doctor.sh 自检检查模板分发与新初始化器完整性；不改变业务项目原有 specs 门禁含义。
- 新模块、规则变更、实现变更、接口变化、偏差修复、验收和发布，各自有明确的受影响资料更新清单；MAP 只在导航变化时更新。
- 原有前端业务规范、tokens、权限和危险区语义保持。新增验收场景引用单一 verification 文档；明确登录/权限/会话变化也是独立QA触发，避免遗漏。

## Task 4：以行为与路径验证

先写能失败的契约，再实现新脚本。新增 tests/harness/test-project-knowledge.sh，复用 testlib；避免逐句镜像测试。

- 无参不生成；help、dry-run、未知域/参数、缺少参数值及非法名称返回可解释状态；拒绝越界/符号链接逃逸。
- 每个domain与all都能生成期望文件；status为draft，模块/案例正确实例化；源模板与已有用户文件不被改写。
- 重复运行不重复索引；在已有自定义根/领域/模块MAP上增补条目，不破坏已有文字。
- 部分领域与全部领域生成后的本地链接均可解析；在两套前端初始化fixture里验证与specs/token引用兼容。
- 外部模板、需求draft、经验记录不会影响active前端specs状态。
- 断开模板分发或目标目录越界时明确失败，不能静默成功。
- 完整自检、doctor strict、shell语法与diff检查通过；清楚记录未覆盖的业务运行态。

## 完成标准

- 用户列出的每种资料都有模板/已有唯一来源映射；截图额外经验、badcase与图示也有按需入口。
- 可由通用Harness分发并在临时目标项目实际生成和索引；不是只在说明文档列出未来目录。
- 独立QA通过；普通问题交原执行者修复、原QA复验；无协作子工具时由主Agent代触发任务，不把普通问题升级为用户决策。
- 最终报告覆盖内容、关键文件、验证、风险；保持当前分支且不提交、不推送、不合并。

## 完成与验收记录

- 已提供31项模板清单及全部对应模板；按需生成覆盖五个领域、指定模块和案例，图示已保存并从总MAP可达。
- 已实现显式生成、template→draft、预览、既有文件保护、根/领域/最近层MAP登记和幂等去重；experience与badcase同时有根入口。
- 静态QA发现的占位符误用、公共规则重复、证据状态与发布来源/核对时间问题均由原资料执行者修复，原QA复验通过。
- 工具QA实测源缺失、源/目标符号链接、目录穿越、保留MAP、自定义索引、名称冲突、两套前端初始化及active项目doctor等场景；剩余根badcase导航问题已由原工具执行者修复并补回归，原QA最终结论为可交付。
- 主Agent最终运行 `bash scripts/verify-harness.sh --self`：13组测试、468项断言通过；其中导航80项，知识资料173项。
- `bash scripts/doctor.sh --self --strict`、逐文件Shell语法、差异格式与新增文本空白检查通过；原init-specs、specs-state和两套Hooks与HEAD一致。
- doctor仅保留既有空docs/specs目录提示；本轮没有业务功能改动，不进行业务运行态验收，不生成或声称真实项目业务事实。
- 所有改动留在codex/harness-2.0，未提交、未推送、未合并；前一轮未提交成果保持。
