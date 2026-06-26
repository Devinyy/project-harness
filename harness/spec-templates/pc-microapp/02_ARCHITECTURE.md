# 02_ARCHITECTURE.md

> 🧩 模版骨架（A 精炼版）：保留结构，正文按真实代码填充；拿不准标 `// TODO: 待确认`，禁止编造。

---
owner: Frontend Team
last_verified: <生成时填写>
status: template
purpose: 目录分层、模块划分、路由组织、数据流、状态管理与扩展边界
---

## 通用分层模型（MVVM · harness 固定基线，不要按项目改写）

> 团队不变的架构基线，新项目沿用即可；项目专属的子应用/端口/产物在下面各 `<填写>` 节补全。目录名以真实代码为准，禁止编造。

前端按 MVVM 分层，依赖**只能单向向下**，不得反向或跨层穿透：

| 层 | 职责 | PC 微前端类落点 |
|----|------|----------------|
| View（视图） | 模板渲染、交互事件、loading/empty/error 三态 | `apps/*/src/views/`、`apps/*/src/components/` |
| ViewModel（视图模型） | 页面状态、副作用、DTO→VM 映射、跨组件共享状态 | composable `useXxx` + Pinia `apps/*/src/store/` |
| Model（数据） | 接口调用、请求/响应 DTO、领域数据 | `apps/*/src/request/`（经 `@platform/http-client`） |
| 基础设施 | 请求封装、认证、路由、micro 通信、全局壳 | `packages/*`（@platform/http-client、micro-bridge）、`apps/micro-main/` 基座 |

**依赖方向（红线）**
- View → ViewModel → Model → 基础设施；禁止反向依赖、禁止跨层直连
- View 不直接 import 请求层：页面/组件取数必须经 composable 或 store，禁裸 axios/fetch（走 `@platform/http-client`）
- Model 只返回类型显式的 DTO，UI 关心的派生计算放 ViewModel，不写进接口层
- 基础设施是危险区（`packages/*` 与 `apps/micro-main/` 基座），禁为单页面/单 app 修改，详见 `11_DANGEROUS_AREAS.md`
- 跨 app 不直接 import（走 `@platform/*` 或 micro-bridge）

**各层边界**
- **Model**：一领域一文件，方法名 getXxx/createXxx/updateXxx/deleteXxx，返回值显式 DTO 类型
- **ViewModel**：业务状态与副作用集中在此；把 Model 的 DTO 映射成视图所需 VM；跨页/跨组件共享状态用 Pinia store 或 composable，不要 prop drilling
- **View**：只消费 ViewModel 暴露的状态与方法，必须覆盖 loading/empty/error；不写接口请求与复杂业务计算；按钮权限走 `hasPerm` 约定

**反模式（review 必查）**
- 页面/组件里裸调接口或直接 axios/fetch
- 把后端 DTO 直接绑模板渲染（应在 ViewModel 转 VM）
- 业务逻辑写在 View，导致组件无法复用、无法测试
- 为局部需求修改 `packages/*` 共享包或 `apps/micro-main/` 基座

## 总体分层
<填写：在上面通用分层模型基础上，补本项目的具体分层落点/特例（子应用划分、特殊层）；与通用模型完全一致则写「遵循通用分层模型」>

## 目录结构与职责
<填写：依据真实代码/配置提炼>

## 模块/子应用/分包划分（含端口）
<填写：依据真实代码/配置提炼>

## 路由组织方式
<填写：依据真实代码/配置提炼>

## 数据流
<填写：依据真实代码/配置提炼>

## 状态管理
<填写：依据真实代码/配置提炼>

## 构建与发布
<填写：依据真实代码/配置提炼>

## 扩展规则与反模式
<填写：依据真实代码/配置提炼>

