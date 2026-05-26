# 11_DANGEROUS_AREAS.md

---
owner: Frontend Team
last_verified: 2026-05-08
status: active
purpose: 标记那些修改成本高、影响面大、容易引发回归的问题区域，并给出修改前检查、提交流程和回滚建议。
primary_readers:
  - Frontend Developers
  - Reviewers
  - AI Agents
related:
  - 02_ARCHITECTURE.md
  - 11_DANGEROUS_AREAS.md
---

## 1. 风险等级定义

### P0：关键基础设施

一旦改错，可能导致：应用无法启动、大面积白屏、登录失效、全站请求异常、权限系统失效

### P1：高影响公共模块

一旦改错，可能导致：多个页面共同异常、某业务域普遍回归

### P2：中风险共享模块

一旦改错，影响若干模块，但一般可局部回滚。

---

## 2. 本项目危险区清单

### 2.1 主基座应用入口（P0）

**路径**：

- `apps/micro-main/src/main.ts`
- `apps/micro-main/src/App.vue`

**风险**：

- Pinia / Router / 全局插件注册顺序错乱
- micro-app 初始化顺序错误导致子应用无法加载
- 全局错误处理被移除

**改动前必须确认**：

- 所有子应用仍可正常加载
- 登录、首页、404 路由正常

---

### 2.2 微前端子应用注册与通信（P0）

**路径**：

- `apps/micro-main/src/micro/` （`start.ts` / `runtime.ts` / `transport.ts` / `registry.ts`）
- `apps/*/src/micro/` （各子应用 bridge 客户端）
- `packages/micro-bridge/src/index.ts`（IPC 协议定义）

**风险**：

- `runtime.ts` 暴露给子应用的 `window.navigateTo`、`window.mainRefreshToken` 等方法签名改变 → 子应用调用报错
- `transport.ts` token/userInfo 下发格式改变 → 子应用无法获取认证信息
- `registry.ts` 子应用注册 URL 配置错误 → 子应用加载失败
- `micro-bridge` IPC 事件名或协议格式改变 → 双端通信失效

**改动前必须确认**：

- 与对应子应用的 bridge 客户端保持协议一致
- 所有子应用均能收到正确的 token 和 userInfo
- token 刷新流程（子应用请求 → 主基座响应 → 下发新 token）正常

---

### 2.3 认证与 Token 管理（P0）

**路径**：

- `apps/micro-main/src/request/tokenProvider.ts`（主基座 token 读写与刷新调度）
- `apps/micro-main/src/request/requestRefreshPolicy.ts`（预刷新策略）
- `packages/auth-session/src/index.ts`（token 存储接口）
- `packages/http-client/src/index.ts`（Axios 拦截器 + 401 处理 + 重试逻辑）

**风险**：

- 修改 token 存储 key → 所有子应用 token 读取失败，全站 401
- 修改预刷新阈值 → 大量请求携带过期 token
- 修改 401 重试逻辑 → 可能产生重试风暴或永久 401 循环
- 修改 JWT decode 逻辑 → 过期判断失效

**改动前必须确认**：

- token 在 localStorage 中的 key 未变化（key: `user-auth`）
- 主基座 401 → refresh → 重试的整个链路仍正常
- 子应用通过 micro-bridge 请求刷新的流程仍正常
- 不同角色登录后 token 均可正常刷新

---

### 2.4 路由系统（P0）

**路径**：

- `apps/micro-main/src/router/index.ts`（路由创建 + 守卫）
- `apps/micro-main/src/router/modules/`（路由模块定义）
- `apps/micro-main/src/utils/menuUtils.ts`（菜单 → 动态路由转换）
- `apps/micro-main/src/store/modules/permission.ts`（动态路由注册）

**风险**：

- 路由守卫逻辑变化 → 登录后跳转异常或无限重定向
- `menuUtils.ts` 菜单转路由逻辑变化 → 菜单对应页面无法访问
- 动态路由注册时机变化 → 刷新后路由丢失（白屏）
- 子应用路由（`/micro-app/*`）配置变化 → 子应用无法挂载

**改动前必须确认**：

- 不同角色登录后菜单和路由均正确
- 刷新页面后路由不丢失
- 权限不足时正确跳转 403/404
- 子应用路由正确加载

---

### 2.5 全局状态（Permission / User Store）（P0/P1）

**路径**：

- `apps/micro-main/src/store/modules/permission.ts`（权限 + 菜单 + 动态路由）
- `apps/micro-main/src/store/modules/user.ts`（当前用户信息）

**localStorage / sessionStorage keys**（不得随意改名）：

- `user-auth`：token
- `user`：用户信息
- `user-menu`：菜单缓存
- `user-permissions`：权限缓存（sessionStorage）

**风险**：

- 修改 store 字段结构 → 依赖该 store 的所有组件渲染异常
- 修改 localStorage key → 刷新后无法恢复登录状态
- 清除 store 时序错误 → 权限状态脏读，用户看到不该看的菜单

**改动前必须确认**：

- 登录 → 获取用户信息 → 获取菜单 → 生成动态路由的完整链路
- 退出登录后 store 和 storage 均已清除
- 不同角色切换后 store 正确重置

---

### 2.6 HTTP Client 公共拦截器（P0）

**路径**：

- `packages/http-client/src/index.ts`（`@platform/http-client`）

**注意**：此包被**所有** app 和子应用依赖，修改影响面极大。

**风险**：

- 请求拦截器 auth header 注入逻辑变化 → 全站 401
- 响应拦截器错误处理逻辑变化 → 错误提示异常或静默失败
- BigInt 转 string 的 JSON 转换逻辑变化 → 大整数字段解析错误
- 超时 / 重试配置变化 → 性能或重试风暴

**改动前必须确认**：

- 在 **所有** app（micro-main、app-merchant、app-product）中验证请求正常
- token 注入、刷新、重试链路完整测试
- 错误情况（401、500、网络断开）均有合理处理

---

### 2.7 共享包（@platform/*）（P0/P1）

**路径**：

- `packages/shared-types/src/index.ts`
- `packages/shared-utils/src/index.ts`
- `packages/auth-session/src/index.ts`
- `packages/micro-bridge/src/index.ts`

**风险**：

- 修改 `shared-types` 中的 `BaseResponse<T>` 结构 → 所有 app 的 API 响应解析失败
- 修改 `auth-session` 的 token key 或接口 → 所有 app token 管理失效
- 修改 `micro-bridge` 的 IPC 协议事件名 → 主基座和子应用通信断裂
- 修改 `shared-utils` 的 bigint 转换工具 → 大整数字段解析异常

**改动前必须确认**：

- 变更是否向后兼容（包已被多个 app 依赖）
- 是否需要先走技术方案评审

---

### 2.8 构建与工程配置（P0）

**路径**：

- `package.json`（root，pnpm workspace + overrides）
- `pnpm-workspace.yaml`
- `tsconfig.base.json`
- 各 app 的 `vite.config.ts`
- `eslint.config.mjs`
- `.prettierrc.json`

**风险**：

- `pnpm overrides` 中 `dcgj-ui` 版本变化 → UI 组件行为全面变化
- `tsconfig` strict 配置变化 → 大量类型报错
- Vite alias 配置（`@platform/*` 路径映射）变化 → 编译时找不到模块
- ESLint 规则变化 → CI lint 检查大面积失败

**改动前必须确认**：

- 本地 dev 构建正常
- `pnpm run validate`（typecheck + lint）通过
- 生产构建（`pnpm run build:prod`）产物正常

---

### 2.9 全局样式（P1）

**路径**：

- `apps/micro-main/src/style/`（全局样式入口）

**风险**：

- CSS reset 或全局变量变化 → 所有子应用视觉异常（子应用运行在 micro-app 沙箱中，主基座样式可能渗透）

---

## 3. 修改危险区前必须做的事

在改动上述区域前，至少完成：

1. 说清楚为什么必须改这里
2. 盘点影响范围（哪些 app、哪些页面）
3. 查找所有调用方（`grep` 搜索）
4. 确认是否有更局部的替代方案
5. 写出回滚方式
6. 补齐最低限度自测计划

P0 改动额外要求：

- 至少一位熟悉该模块的 reviewer
- 必要时先出技术方案
- 明确灰度或回滚策略

---

## 4. 典型红线

- 为满足单页面需求直接修改 `packages/http-client`（应该通过 option/callback 扩展）
- 在主基座路由守卫中追加局部业务逻辑
- 随意修改 token 存储的 localStorage key
- 修改 micro-bridge IPC 事件名不同步修改双端代码
- 修改 `shared-types` 中的基础类型破坏向后兼容
- 在生产构建配置中直接调整 split / alias / define 等关键项

---

## 5. 自测回归范围（危险区改动后）

建议覆盖：

- 登录 / 退出登录
- 刷新页面后登录态恢复
- 不同角色菜单和路由访问
- 主基座导航到子应用
- 子应用发起 API 请求（含 token 注入）
- token 过期自动刷新链路（可用短 token 测试）
- 商家列表、商品列表等核心页面

---

## 6. 真实性校验

- [x] P0 危险区路径已对应真实代码文件
- [x] localStorage key 已从代码中提取（`user-auth`、`user`、`user-menu`）
- [x] packages/ 依赖关系已盘点
- [ ] 按钮权限机制确认后补充
- [ ] 生产部署/回滚流程待补充
