# docs/specs/INDEX.md（模版骨架 · uni-app 多端）
> 🧩 生成后删除本行，把 `<...>` 换成真实项目名。不预加载，按下表 head/grep 查阅。

这是 uni-app 多端的前端领域入口，只记录当前项目的实现事实。通用知识见 [docs/harness/knowledge.md](../../docs/harness/knowledge.md)，通用验收见 [docs/harness/verification.md](../../docs/harness/verification.md)；用户确认的目标和业务决策按知识契约放在项目约定的需求/决策资料中，不在这里伪造。

本项目：`<项目名>`（多端商城，uni-app + Vue3 + uview-plus，H5/小程序/App）。

| 文件 | 何时查 |
|------|--------|
| 00_PROJECT_FACTS | 栈/命令/目录/认证/多端（先读）|
| 01_PROJECT_OVERVIEW | 定位/环境/外部依赖 |
| 02_ARCHITECTURE | src/ 结构、pages.json 路由/分包、多端策略 |
| 03_BUSINESS_DOMAIN | 多租户/多渠道、商城实体与状态 |
| 04_CODING_STANDARDS | 命名/类型/样式（含 padding→box-sizing）|
| 05_COMPONENT_PATTERNS | 组件拆分复用 |
| 06_UI_COMPONENT_GUIDE | uview-plus、Figma 切图/图片素材规则 |
| 07_API_CONTRACTS | 接口/响应/错误码 |
| 08_TASK_PLAYBOOKS | 常见任务步骤 |
| 09/10 | 技术方案模板/流程 |
| 11_DANGEROUS_AREAS | ⚠️ 改请求/认证/入口/路由/pages.json/manifest 前必读 |
| 12_TROUBLESHOOTING | 排障 |
| 13_AGENT_POLICY | Allowed / Blocked / Ask First 权限边界 |
| uview-components/COMPONENT_INDEX | 常用 uview-plus 组件与封装 |
| examples/ skills-reference/ | 参考 |
| dangerous-zones.txt | 机器可读危险区（驱动 hooks）|

纪律：head -40/grep -A 10，不 cat 全文；以真实代码为准，拿不准标 `// TODO: 待确认`。

状态分离：`03_BUSINESS_DOMAIN.md` 区分目标与实现事实；`00_PROJECT_FACTS.md`、架构、API 和组件文档只写可取证的当前实现。`status: active` 需要人工复核，不等于用户业务验收；验收顺序和受阻/复验处理统一引用 [verification contract](../../docs/harness/verification.md)。
