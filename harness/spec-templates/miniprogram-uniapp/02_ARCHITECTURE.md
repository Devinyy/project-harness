# 02_ARCHITECTURE.md

> 🧩 模版骨架（A 精炼版）：保留结构，正文按真实代码填充；拿不准标 `// TODO: 待确认`，禁止编造。

---
owner: Frontend Team
last_verified: <生成时填写>
status: template
purpose: 目录分层、模块划分、路由组织、数据流、状态管理与扩展边界
---

## 通用分层模型（MVVM · harness 固定基线，不要按项目改写）

> 团队不变的架构基线，新项目沿用即可；项目专属目录/端/命令在下面各 `<填写>` 节补全。目录名以真实代码为准，禁止编造。

前端按 MVVM 分层，依赖**只能单向向下**，不得反向或跨层穿透：

| 层 | 职责 | uni-app 多端类落点 |
|----|------|--------------------|
| View（视图） | 模板渲染、交互事件、三态展示、多端 `#ifdef` 差异 | `src/pages/<模块>/<xxx>-page.vue`、`src/components/` |
| ViewModel（视图模型） | 页面状态、副作用、DTO→VM 映射、跨页共享状态 | `src/composables/` 的 `useXxx`（**不建 stores/**，共享也用 composable） |
| Model（数据） | 接口调用、请求/响应 DTO | `src/api/`（一领域一文件，经 `@/utils/request`）、`src/types/` DTO |
| 基础设施 | 请求封装、认证、路由 | `src/utils/`（request.ts/auth.ts/router.ts） |

**依赖方向（红线）**
- View → ViewModel → Model → 基础设施；禁止反向依赖、禁止跨层直连
- View 不直接 import `src/api/*` 或 `@/utils/request`：取数必须经 composable，禁裸 `uni.request`/`luch-request`
- Model 只返回类型显式的 DTO，UI 关心的派生计算放 ViewModel，不写进接口层
- 基础设施 `src/utils/` 与 `src/components/basic/` 是危险区，禁为单页面修改，详见 `11_DANGEROUS_AREAS.md`

**各层边界**
- **Model**：一领域一文件，方法名 getXxx/createXxx/updateXxx/deleteXxx，DTO 在 `src/types`
- **ViewModel**：业务状态与副作用集中在 `useXxx`；副作用 `onUnmounted` 清理；把 DTO 映射成 VM；跨页共享状态用 composable，**不要新建 services/ stores/ router/ 目录**
- **View**：只消费 composable 暴露的状态与方法，必须覆盖 loading/empty/error；新增页面必须登记 `src/pages.json`；不写接口请求与复杂业务计算；多端差异一律 `#ifdef/#ifndef`

**反模式（review 必查）**
- 页面/组件里裸调 `uni.request` 或直接 import `src/api/*`
- 把后端 DTO 直接绑模板渲染（应在 composable 转 VM）
- 新建 stores/services/router 目录绕过约定
- 为局部需求修改 `src/utils/request.ts`、`auth.ts` 或 `src/components/basic/`

## 总体分层
<填写：在上面通用分层模型基础上，补本项目的具体分层落点/特例（特殊层、目录差异）；与通用模型完全一致则写「遵循通用分层模型」>

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

