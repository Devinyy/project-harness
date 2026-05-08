# 12_TROUBLESHOOTING.md

---
owner: Frontend Team
last_verified: 2026-05-08
status: active
purpose: 提供按症状分类的前端排障路径，帮助更快定位启动失败、白屏、权限异常、接口异常、状态不同步、构建失败和性能问题。
primary_readers:
  - Frontend Developers
  - QA
  - Oncall Engineers
  - AI Agents
related:
  - 02_ARCHITECTURE.md
  - 07_API_CONTRACTS.md
  - 08_TASK_PLAYBOOKS.md
  - 11_DANGEROUS_AREAS.md
---

## 0. 本项目快速定向

| 症状 | 优先看 |
|------|--------|
| 子应用白屏/加载失败 | 第 6 节（微前端）|
| token 失效/401 循环 | 第 8 节 |
| 列表空白/数据不对 | 第 11 节 |
| 状态标签显示 undefined | 第 9.3 节（枚举映射）|
| 筛选/分页/数据不同步 | 第 12 节（URL 状态）|
| 本地启动失败 | 第 4 节 |
| packages/ 改动后构建报错 | 第 14 节 |

---

> 使用说明：
>
> - 本文件强调“先收集证据，再判断层级，再下结论”
> - 对已经复盘过的线上事故，建议把可复用部分沉淀进来
> - 若某类问题经常发生，建议补充最短排查路径和命令

---

## 1. 排障总原则

遇到问题时，默认按以下顺序处理：

1. **先复现**
2. **先分层**
   - 是环境问题、构建问题、路由问题、权限问题、API 问题、状态问题，还是 UI 问题
3. **先收集证据**
   - 错误信息、接口返回、控制台日志、网络请求、用户角色、页面路径、环境变量
4. **先找根因**
   - 不要只修表面症状
5. **修后回归相邻路径**
   - 不要只测一个按钮

---

## 2. 最少需要收集的信息

无论什么问题，建议先收集：

- 问题环境：local / dev / staging / prod
- 页面路径 / 路由参数 / query 参数
- 当前角色 / 账号 / 租户
- 触发步骤
- 控制台报错
- Network 中失败请求
- 最近改动文件
- 是否仅某浏览器 / 某环境出现
- 是否可稳定复现

如果是线上问题，再补充：

- 发布版本
- 发布时间
- 监控告警
- 受影响范围
- 是否可回滚

---

## 3. 快速分层判断

### 3.1 页面白屏 / 无法加载

先判断：

- 是否构建资源加载失败
- 是否根入口报错
- 是否路由守卫死循环
- 是否关键 Provider 缺失
- 是否环境变量缺失

### 3.2 页面能打开但数据不对

先判断：

- 请求是否成功
- 适配逻辑是否错
- store 是否脏
- 权限是否导致字段缺失
- 筛选 / query 参数是否错

### 3.3 按钮点了没反应

先判断：

- 是否被禁用
- 事件有没有绑定
- 权限是否拦截
- 校验是否没过
- 请求是否发出
- loading 状态是否没恢复

### 3.4 只有某角色有问题

先判断：

- 页面权限
- 按钮权限
- 数据权限
- 默认角色配置
- 用户上下文缓存

---

## 4. 启动失败 / 本地跑不起来

常见现象：

- 安装依赖失败
- 启动命令报错
- 端口冲突
- Node 版本不兼容
- 环境变量缺失
- 构建工具配置错误

排查顺序建议：

1. 确认 Node / 包管理器版本
2. 重新安装依赖
3. 检查 lockfile 是否一致
4. 检查 `.env` 是否存在且格式正确
5. 查看构建工具报错栈
6. 检查路径 alias 和 tsconfig / vite / webpack 配置

本项目常用命令：

```bash
# 版本确认
node -v          # 推荐 Node 18+
pnpm -v

# 安装依赖（必须用 pnpm，不能用 npm/yarn）
pnpm install

# 启动全部子应用
pnpm run dev

# 启动单个子应用
pnpm --filter app-product run dev    # 端口 5174
pnpm --filter app-merchant run dev   # 端口 5175
pnpm --filter micro-main run dev     # 端口 5173（主基座）

# 类型检查（CI 必过）
pnpm run typecheck

# lint + typecheck
pnpm run validate

# 生产构建
pnpm run build:prod
```

排查顺序建议：

1. 确认 Node 版本（推荐 18+），确认使用 pnpm（不用 npm/yarn）
2. `pnpm install`（清 node_modules 后重装）
3. 检查各 app 的 `.env.development` 是否存在，`VITE_APP_API_URL` 是否配置
4. 看 Vite 报错栈（常见：alias 路径找不到、tsconfig paths 未配）
5. `pnpm run validate` 确认无 TS 编译错误

---

## 5. 白屏 / 首屏崩溃

常见原因：

- 根组件异常
- Provider 顺序问题
- 路由配置错误
- 动态导入 chunk 加载失败
- 全局样式或主题初始化异常
- 环境变量缺失导致初始化失败

排查步骤：

1. 看控制台第一条报错
2. 看 Network 是否有资源 404 / 403
3. 确认路由是否进入正确页面
4. 临时关闭最近新增的全局逻辑定位范围
5. 检查是否是某个 Provider 或全局 store 初始化崩溃

若是线上：

- 看监控平台错误堆栈
- 看是否与某次发布时间重合
- 判断是否可立即回滚

---

## 6. 微前端子应用异常（本项目特有）

本项目使用 `@micro-zoe/micro-app`，子应用（app-product、app-merchant）以 iframe 沙箱方式嵌入主基座（micro-main）。

### 6.1 子应用白屏 / 加载失败

排查顺序：

1. **看主基座 Console**：是否有 micro-app 注册失败或 URL 404 报错
2. **检查 `registry.ts`**：子应用注册 URL 是否与当前端口一致（`apps/micro-main/src/micro/registry.ts`）
3. **子应用是否已启动**：micro-main 加载子应用时子应用本身必须在运行
4. **看子应用 Console**：子应用内部是否有报错（需打开子应用独立端口查看）
5. **检查 `transport.ts`**：token 和 userInfo 是否正确下发（`apps/micro-main/src/micro/transport.ts`）

### 6.2 子应用收不到 token / 全部 401

排查顺序：

1. 确认 `transport.ts` 的 `postMessage` 触发时机（在 token 已就绪后）
2. 确认子应用 bridge 客户端（`apps/*/src/micro/`）是否正确监听并写入 token
3. 确认 token 写入 localStorage 的 key 是 `user-auth`（不能改名，见 `11_DANGEROUS_AREAS.md`）
4. 确认子应用的 `@platform/http-client` 拦截器在读正确的 key

### 6.3 `window.navigateTo` / `window.mainRefreshToken` 不可用

这些方法由主基座的 `runtime.ts` 注入到 `window`，子应用通过 `window.navigateTo(path)` 跳转：

1. 确认主基座 `runtime.ts` 已运行
2. 确认调用时机（子应用挂载后才能调用，不要在挂载前调用）
3. 确认方法签名未被修改（改动 `runtime.ts` 是 P0 危险操作）

---

## 7. 路由异常

症状可能包括：

- 页面打不开
- 菜单点击无反应
- 页面跳转到错误地址
- 参数丢失
- 返回列表后筛选条件消失
- 登录后循环跳转

排查步骤：

1. 确认路由定义与实际路径
2. 检查菜单与路由映射
3. 检查守卫逻辑
4. 检查 query / params 解析
5. 检查权限是否挡住路由
6. 检查 base path / 部署路径

---

## 8. 登录 / Token / 权限异常

常见现象：

- 明明已登录却被踢回登录页
- 子应用全部 401
- 接口报 401 后无限重试
- 菜单能看到但按钮不能点
- 某角色缓存了旧权限

排查步骤：

1. **检查 localStorage `user-auth` 是否存在且未过期**（DevTools → Application → Local Storage）
2. **检查 token 刷新链路**：主基座 `tokenProvider.ts` → 401 发生 → `requestRefreshPolicy.ts` 预刷新 → 新 token 写回
3. **子应用 401**：确认子应用是否通过 micro-bridge 收到最新 token（见第 6.2 节）
4. **无限 401 循环**：通常是 refresh 接口本身也 401，或重试逻辑有 bug — 查 `@platform/http-client` 的 401 处理，这是 P0 危险区
5. **权限缓存问题**：退出登录后确认 `user-auth`、`user`、`user-menu`、`user-permissions`（sessionStorage）均已清除
6. **菜单有但接口 403**：属于数据权限问题，后端控制，前端无法绕过

---

## 9. API 请求异常

### 9.1 请求没发出

先看：

- 事件是否触发（composable 的函数是否被调用）
- `watch(route.query)` 是否触发（列表页依赖 URL 变化驱动请求）
- 校验是否阻止了提交
- 条件判断是否提前 return

### 9.2 请求发出了但失败

先看：

- URL / method / params / body 是否正确
- token 是否注入（看 Request Headers 的 Authorization）
- 是否走错了环境地址（`.env.development` 的 `VITE_APP_API_URL`）
- 后端是否报业务错误（code 非 0 时 `@platform/http-client` 会 toast 并 reject）

### 9.3 请求成功但 UI 不对

先看：

- **mapper 层**（`api/domain.xxx.mapper.ts`）：数字枚举是否正确映射为字符串（如后端 `status: 1` → 前端 `'PENDING'`）
- **`unwrapApiData`**：响应是否有包装层需要解包（部分接口直接返回 PageResult，部分返回 `{data: PageResult}`）
- `StatusTag` 的 `value` 是否匹配 `STATUS_LABEL` 常量的 key（value 未定义时会显示 undefined）
- 查询条件是否已通过 `route.query` 同步
- 列渲染 / 状态映射 / 默认值

---

## 10. 表单异常

常见现象：

- 提交按钮无法点击
- 校验不生效
- 编辑回填错误
- 提交成功后页面未刷新
- 错误提示不显示
- 关闭重开弹层后残留旧值

排查步骤：

1. 看字段注册与 name 是否一致
2. 看默认值注入时机
3. 看同步 / 异步校验规则
4. 看提交函数是否真正执行
5. 看表单状态 reset 时机
6. 看后端字段错误映射是否正确

---

## 11. 列表 / 表格异常

常见现象：

- 筛选无效
- 分页异常
- 删除后总数不对
- 行操作状态没刷新
- 列内容展示错
- 批量操作条件不对

排查步骤：

1. 检查查询参数是否正确传递
2. 检查分页协议页码和总数字段
3. 检查 adapter 是否把字段转错
4. 检查成功后是否刷新或局部更新
5. 检查缓存 / query key 是否正确
6. 检查表格列渲染和状态标签映射

---

## 12. 状态不同步 / 脏数据

常见原因（本项目特有）：

- 筛选条件同时维护在 `reactive(query)` 和 URL，互相覆盖（根因：应以 URL 为唯一真值，通过 `watch(route.query)` 触发请求）
- `draftQuery` 与 `query` 不同步（draftQuery 是用户输入中途态，提交后才同步）
- 弹层关闭时 `currentRecord` 未重置，导致快速切换后弹层显示上一条数据
- 列表页 `pageNum > totalPages` 时未自动退回（composable 内需要判断）
- Pinia store `$reset()` 未在路由离开时调用，导致下次进页面残留旧状态

排查步骤：

1. 检查列表 composable 的 `query` 是否以 `route.query` 为真值（watch + readQueryFromRoute）
2. 检查弹层 `open`/`currentRecord` 是否在 views 层管理（不在 composable 里）
3. 看 store 是否有 `$reset()` 时机配置
4. 看 `watch(route.query)` 的 `{ immediate: true }` 是否存在
5. 看请求并发时是否可能旧数据覆盖新数据（通常 watch immediate 模式不会，但手动触发要注意）

---

## 13. 样式 / UI 异常

常见现象：

- 样式错位
- 间距不一致
- 弹层层级异常
- 深浅主题错乱
- 文案溢出
- 某浏览器展示异常

排查步骤：

1. 看最近是否改了全局样式或基础组件
2. 看类名作用域是否冲突
3. 看布局容器和滚动容器
4. 看 z-index 与弹层挂载节点
5. 看是否硬编码尺寸破坏响应式
6. 看是否绕过了设计 token

---

## 14. 构建 / 发布异常

常见现象：

- 本地能跑，CI 失败
- dev 正常，prod 白屏
- 动态 chunk 404
- 环境变量在生产失效
- Source Map / 监控上传失败

排查步骤：

1. 对比本地与 CI 的 Node 版本（推荐 18+）
2. 检查 `pnpm run validate`（typecheck + lint）是否通过
3. 检查 Vite alias（`@platform/*` 路径映射）是否在 `vite.config.ts` 中正确配置
4. **`packages/*` 改动后**：确认所有引用该包的 app 均已重新 `pnpm install` 且类型无报错
5. 检查各 app `.env.production` 的 `VITE_APP_API_URL` 是否指向正确环境
6. 检查构建产物和部署路径（子应用静态资源路径需与 micro-main 的 `registry.ts` 注册 URL 一致）

---

## 15. 性能问题

常见现象：

- 列表卡顿
- 首屏慢
- 输入防抖失效
- 页面切换慢
- 大表单输入延迟

排查方向：

- 是否重复渲染
- 是否在 render / template 中做重计算
- 是否缺少缓存 / memo / computed
- 是否请求过多
- 是否未做懒加载
- 是否表格 / 列表缺少虚拟化
- 是否 store 更新粒度过大

---

## 16. 排障输出模板

建议每次排障都至少记录：

- 问题标题：
- 影响环境：
- 影响角色：
- 复现步骤：
- 观察到的现象：
- 根因：
- 修复方式：
- 回归点：
- 是否需要更新 docs：

---

## 17. 何时升级为事故处理

满足以下任一条件时，应按事故处理流程升级：

- 影响大量用户
- 核心链路不可用
- 登录 / 支付 / 发布 / 提交等主流程中断
- 无法快速定位且仍在扩大
- 需要紧急回滚

---

## 18. 排障原则补充

排障时应注意：

- 先分类问题层级，不要直接改第一眼看到的代码
- 先收集报错和请求信息
- 给出“可能根因 -> 验证方法 -> 修复建议”的链路
- 不要把没有证据的猜测包装成结论
- 修完后列出回归范围和是否需要补文档
