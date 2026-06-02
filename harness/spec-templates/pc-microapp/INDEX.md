# docs/specs/INDEX.md（模版骨架 · PC 微前端）
> 🧩 生成后删除本行，把 `<...>` 换成真实项目名。不预加载，按下表 head/grep 查阅。

本项目：`<项目名>`（PC 运营平台，Vue3 + micro-app + dcgj-ui + @platform/http-client）。

| 文件 | 何时查 |
|------|--------|
| 00_PROJECT_FACTS | 栈/命令/目录/认证（先读）|
| 01_PROJECT_OVERVIEW | 定位/环境/外部依赖 |
| 02_ARCHITECTURE | 基座+子应用、端口、micro、Hash 路由 |
| 03_BUSINESS_DOMAIN | 业务域、权限模型 |
| 04_CODING_STANDARDS | 命名/类型/样式 |
| 05_COMPONENT_PATTERNS | 组件拆分复用 |
| 06_UI_COMPONENT_GUIDE | dcgj-ui 用法 |
| 07_API_CONTRACTS | 接口/响应/错误码 |
| 08_TASK_PLAYBOOKS | 常见任务步骤 |
| 09/10 | 技术方案模板/流程 |
| 11_DANGEROUS_AREAS | ⚠️ 改基座/共享包/路由/请求/构建前必读 |
| 12_TROUBLESHOOTING | 排障 |
| dcgj-components/COMPONENT_INDEX | dcgj-ui 组件 |
| examples/ skills-reference/ | 参考 |
| dangerous-zones.txt | 机器可读危险区（驱动 hooks）|

纪律：head -40/grep -A 10，不 cat 全文；以真实代码为准，拿不准标 `// TODO: 待确认`。
