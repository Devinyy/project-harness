# 02_ARCHITECTURE.md

---
owner: Frontend Team
last_verified: 2026-05-08
status: active
purpose: 说明项目的目录分层、路由组织、数据流、状态管理、请求链路与扩展边界，帮助开发者在架构层做出一致决策。
primary_readers:
  - Frontend Developers
  - Tech Leads
  - AI Agents
related:
  - 01_PROJECT_OVERVIEW.md
  - 03_BUSINESS_DOMAIN.md
  - 11_DANGEROUS_AREAS.md
---

## 0. 当前项目采用情况

- 是否适用：**是**
- 项目形态：**pnpm monorepo + 微前端（@micro-zoe/micro-app）**
- 真实源码根目录：每个 app 下各自的 `src/`（无统一 `src/`）
- 不要使用的目录：
  - `features/`（本项目无此层）
  - `shared/`（本项目无此层，跨 app 共享通过 `packages/*`）
  - `services/`（本项目无此层，API 封装放在各 app 的 `api/` 目录）
  - `app/`（本项目无此层，初始化逻辑在 `main.ts` 和 `bootstrap/`）
- 与模板不同的地方：
  - 没有 `features/` 层，业务组件就在 `components/` 和 `views/` 中
  - API 层叫 `api/`（不叫 `services/`），并使用 mapper/adapter 文件分离类型转换
  - Pinia store 目录名不统一：`micro-main` 用 `store/`，子应用用 `stores/`
  - 共享逻辑在 `packages/*`，按职责拆为独立 workspace 包
- 新增目录规则：
  - 未在本节列出的顶层目录，必须先在技术方案或评审中说明理由

---

## 1. 架构目标

- 微前端隔离：各子应用独立开发、独立部署，通过 micro-bridge IPC 与主基座通信
- 主基座统一管理：登录、token、权限菜单、布局壳只在 `micro-main` 中存在
- 子应用无感知认证：子应用 token 从主基座获取，不自行管理 token 刷新
- 共享包受控：跨 app 通用逻辑只能通过 `packages/*`，不允许跨 app 直接 import

当前架构历史包袱：

- Vite、TypeScript 版本在各 app 间不统一（app-system 已升，其他还是旧版）
- `micro-main` 和部分子应用仍有大量业务逻辑混在 `views/` 中，未拆 composables
- `shared-components` 包目前为空，未实际使用

---

## 2. 总体分层（monorepo 视角）

```text
基座层（micro-main）
├── 登录 / 认证 / token 管理
├── 权限 & 菜单（后端下发 → Pinia store → 动态路由）
├── 布局壳（sidebar + header + tab-router）
└── 微前端容器（micro-app 子应用加载）

子应用层（app-merchant / app-product / app-system / app-org-account）
├── 路由（Hash 模式，独立路由表）
├── 业务页面（views/）
├── 业务组件（components/）
├── Composables（composables/）
├── API 层（api/）
└── 微前端 bridge 客户端（micro/）

共享包层（packages/）
├── @platform/shared-types    # BaseResponse、LoginResult、BaseUser 等
├── @platform/shared-utils    # date、validation、bigint 等工具
├── @platform/http-client     # Axios 封装，含 token 刷新、错误处理
├── @platform/auth-session    # token 读写、session 生命周期
└── @platform/micro-bridge    # 主基座 ↔ 子应用 IPC 协议
```

---

## 3. 目录结构与职责

### 3.1 micro-main（主基座）

```text
apps/micro-main/src/
├── api/                  # 认证、菜单、系统接口
│   ├── auth.ts
│   ├── menu.ts
│   └── system.ts
├── bootstrap/            # 应用启动逻辑
├── components/           # 基座级 UI 组件
├── config/
│   └── domain.ts         # 各子应用 URL（按环境）
├── constants/
├── hooks/                # Vue 3 hooks（基座级）
├── layouts/              # 侧边栏、顶栏、布局外壳
├── micro/
│   ├── index.ts          # micro-app 初始化入口
│   ├── start.ts          # 启动微前端引擎
│   ├── runtime.ts        # 暴露给子应用的方法（window.navigateTo 等）
│   ├── transport.ts      # 子应用数据下发（token、userInfo）
│   └── registry.ts       # 子应用注册
├── pages/                # 基座页面（login、home、404）
├── request/              # HTTP client 初始化 + tokenProvider
│   ├── request.ts
│   └── tokenProvider.ts
├── router/               # 路由主配置 + 动态路由生成
│   └── modules/
├── store/                # Pinia（注意：此处叫 store/ 不叫 stores/）
│   └── modules/
│       ├── permission.ts  # 权限 + 菜单 + 动态路由
│       ├── user.ts        # 当前用户信息
│       ├── setting.ts     # 应用设置
│       └── tabs-router.ts # 标签路由状态
├── style/                # 全局样式
├── types/
└── utils/
    ├── rsa.ts            # RSA 加密（密码登录）
    └── menuUtils.ts      # 菜单 → 路由转换
```

### 3.2 app-merchant（商家管理子应用）

```text
apps/app-merchant/src/
├── api/
│   ├── merchant.ts                  # 商家接口
│   ├── merchant.definitions.ts      # 接口类型定义
│   ├── merchant.query.mapper.ts     # 请求参数转换
│   ├── merchant.detail.mapper.ts    # 详情响应转换
│   ├── merchant.brand.mapper.ts     # 品牌数据转换
│   └── qiniu.ts                     # 七牛云上传 token
├── components/                      # 业务/UI 组件
├── composables/                     # composables（功能逻辑）
├── constants/
├── micro/                           # bridge 客户端（接收主基座数据）
├── request/                         # HTTP client 初始化
│   └── tokenProvider.ts             # 从主基座获取 token
├── router/
│   └── index.ts                     # Hash 路由（/merchant/list 等）
├── stores/                          # Pinia（子应用叫 stores/）
│   └── merchant.ts
├── types/
│   └── merchant.ts                  # MerchantRecord、MerchantStatus 等
└── views/
    └── merchant/
        ├── list.vue
        ├── detail.vue
        ├── form.vue
        └── audit.vue
```

### 3.3 app-product（商品中心子应用）

```text
apps/app-product/src/
├── api/
│   ├── product.ts                          # 商品列表、详情接口
│   ├── product-detail.adapter.ts           # 详情响应转换
│   ├── product-price-rule.ts               # 价格规则接口
│   ├── product-price-rule.adapter.ts       # 价格规则响应转换
│   └── __contracts__/                      # adapter 契约测试
├── components/
│   ├── common/                             # 跨领域通用组件
│   ├── product/                            # 商品域业务组件
│   └── price-rule/                         # 价格规则域业务组件
├── composables/
│   ├── useProductListQuery.ts
│   ├── useProductDetail.ts
│   ├── usePriceRuleListQuery.ts
│   ├── usePriceRuleForm.ts
│   └── usePriceRuleSelection.ts
├── micro/
├── request/
│   └── __contracts__/                      # token/userInfo 契约测试
├── router/
├── types/
│   ├── product.ts                          # ProductRecord、ProductStatus 等
│   └── price-rule.ts                       # PriceRuleRecord、PriceRuleStatus 等
├── utils/
└── views/
    ├── product/
    │   ├── list.vue
    │   └── detail.vue
    └── price-rule/
        ├── list.vue
        ├── detail.vue
        └── form.vue
```

### 3.4 packages（共享包）

```text
packages/
├── shared-types/src/index.ts    # BaseResponse<T>、LoginResult、BaseUser
├── shared-utils/src/index.ts    # formatDate、validatePhone、bigint 转换
├── http-client/src/index.ts     # createHttpClient()，含拦截器、token 刷新
├── auth-session/src/index.ts    # getToken、setToken、clearToken
└── micro-bridge/src/index.ts   # IPC 请求/响应协议定义
```

---

## 4. 路由组织方式

- **主基座**：集中式 + 动态路由（后端菜单生成）
- **子应用**：集中式静态路由，Hash 模式

### 4.1 路由定义位置

| App | 路由文件 |
|-----|---------|
| micro-main | `apps/micro-main/src/router/index.ts` + `src/router/modules/*.ts` |
| app-merchant | `apps/app-merchant/src/router/index.ts` |
| app-product | `apps/app-product/src/router/index.ts` |

### 4.2 主基座路由规则

- 静态路由：`/login`、`/`（首页）、`/:w+`（404）
- 动态路由：登录后从 `permission` store 中根据后端菜单动态注册
- 菜单 → 路由转换逻辑：`apps/micro-main/src/utils/menuUtils.ts`
- 子应用挂载路由：`/micro-app/*`，实际由 micro-app 容器处理

### 4.3 子应用路由规则（以 app-merchant 为例）

- Hash 模式，base 为 `/`
- 路由示例：`#/merchant/list`、`#/merchant/detail/:id?`、`#/merchant/form/:id?`
- 子应用路由不会与主基座路由冲突（运行在各自的 micro-app 沙箱中）

### 4.4 路由状态来源

- ID 参数：path params（`/detail/:id`）
- 筛选条件：页面 local state（目前不持久化到 URL）
- 分页：页面 local state
- 用户信息 / token：全局 store（micro-main）

---

## 5. 数据流

### 5.1 子应用请求链路

```text
用户操作
  → views/ 或 composable
  → api/ 函数调用
  → @platform/http-client（Axios 拦截器注入 token）
  → 后端 API 网关
  → 响应 mapper/adapter 转换
  → 组件 reactive 数据更新
  → UI 重新渲染
```

### 5.2 token / 认证流

```text
micro-main 登录成功
  → token 存入 @platform/auth-session（localStorage）
  → 通过 micro/transport.ts 下发给各子应用（micro-app data 属性）
  → 子应用 micro/transport.ts 接收，写入本地内存
  → 子应用 request/tokenProvider.ts 提供给 @platform/http-client

token 过期时（子应用请求 401）：
  → 子应用通过 micro-bridge 向主基座发送 auth:request-refresh-token
  → 主基座执行 /system/refreshToken
  → 成功后下发新 token 给所有子应用
```

### 5.3 常见状态归属

| 状态类型 | 归属 |
|---------|------|
| 路由参数 | URL（path / query params） |
| 列表筛选条件 | 页面 local state（`ref`/`reactive`） |
| 表格分页 | 页面 local state |
| 表单临时输入 | 页面 local state |
| 用户信息 / 权限 | micro-main `user` store / `permission` store |
| 商家列表缓存 | 暂无（每次进入页面重新请求） |

---

## 6. API 层规范

### 6.1 api/ 文件组织（以 app-merchant 为例）

```text
api/
├── merchant.ts                  # 接口函数（queryMerchantList、getMerchantDetail 等）
├── merchant.definitions.ts      # 接口原始请求/响应 TS 类型
├── merchant.query.mapper.ts     # FilterState → API 请求参数转换
├── merchant.detail.mapper.ts    # 原始响应 → MerchantDetailData 转换
└── merchant.brand.mapper.ts     # 品牌相关响应转换
```

规则：

- 接口函数在 `merchant.ts` 中，**不允许**在 `views/` 或 `composables/` 中裸调 axios
- 类型定义在 `.definitions.ts` 或 `types/` 中
- 数据转换（字段映射、格式化）在 `.mapper.ts` 或 `.adapter.ts` 中
- app-product 已引入 `__contracts__/` 目录用于 adapter 契约测试

### 6.2 HTTP client 使用

```typescript
// 正确：通过 @platform/http-client 封装的实例
import { request } from '@/request'

// 禁止：直接 new axios
import axios from 'axios'  // ❌ 禁止在业务代码中直接使用
```

---

## 7. 微前端通信

主基座暴露给子应用的 window 方法（`apps/micro-main/src/micro/runtime.ts`）：

- `window.navigateTo(path, query)`：子应用触发主基座导航
- `window.mainRefreshToken()`：子应用请求主基座刷新 token
- `window.mainMenuCache()`：子应用请求主基座刷新菜单缓存

micro-bridge IPC 事件：

- `auth:request-refresh-token`：子应用 → 主基座
- `auth:refresh-token-success`：主基座 → 子应用
- `auth:refresh-token-error`：主基座 → 子应用

---

## 8. 权限

- 页面访问权限：`micro-main` 路由守卫根据 `permission` store 中的权限列表判断
- 菜单由后端下发，`menuUtils.ts` 将其转换为动态路由
- 按钮权限：<!-- TODO: 待确认，目前未见统一的按钮权限工具函数 -->
- 无权限时：跳转 404 页面或空白

---

## 9. 构建与发布架构

- monorepo，每个 app 独立构建产物（各自 `dist/`）
- 统一通过 Docker 打包，Nginx 托管静态文件
- 主基座和子应用分别部署，子应用地址在 `domain.ts` 中配置
- 生产环境各子应用通过 CDN/独立域名访问（<!-- TODO: 确认生产域名方案 -->）

---

## 10. 扩展规则

新增需求时，优先按以下顺序扩展：

1. 复用现有页面骨架（在相同 app 的 `views/` 下参考已有页面）
2. 复用已有 composable（在 `composables/` 下查找同类功能）
3. 复用已有 `api/` 文件中的函数
4. 必要时新增局部组件（放在 `components/`）
5. 跨 app 复用才考虑放 `packages/*`（需评审）

### 10.1 新增页面

新增页面时先确认：

- 路由放在当前 app 的 `router/index.ts`
- 页面文件放在 `views/<业务域>/`
- API 函数在 `api/` 对应文件中（或新建 `xxx.ts`）
- 是否影响主基座菜单（需后端配置）

---

## 11. 反模式清单

- 在 `views/` 组件中直接调用 `axios` 或 `fetch`（必须通过 `api/` 层）
- 跨 app 直接 `import`（如 `app-merchant` import `app-product` 的代码）
- 在子应用中自行管理 token 刷新（必须走 micro-bridge 让主基座处理）
- 在 `api/` 层写 UI 逻辑（Toast、Modal）
- 把临时局部状态放入 Pinia store

---

## 12. 真实性校验

- [x] 本文档中的目录在真实项目中存在
- [x] 本文档中的路由、状态管理、请求链路与当前代码一致
- [x] "不要使用的目录"已经补齐
- [ ] 按钮权限机制待确认后补充
- [ ] 生产域名方案待确认后补充
