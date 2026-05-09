# 01_PROJECT_OVERVIEW.md

---
owner: Frontend Team
last_verified: 2026-05-08
status: active
purpose: 提供项目的业务定位、技术栈、环境、运行方式和对外依赖，帮助开发者在最短时间内建立全局认知。
primary_readers:
  - Frontend Developers
  - QA
  - Tech Leads
  - AI Agents
related:
  - 00_INDEX.md
  - 02_ARCHITECTURE.md
  - 03_BUSINESS_DOMAIN.md
  - 11_DANGEROUS_AREAS.md
---

## 1. 项目基础信息

- 项目名称：大厨管家运营管理平台（dc-platform-new）
- 仓库名称：`dc-platform-new`
- 所属团队：大厨团队前端
- 维护负责人：张翔

### 1.1 一句话描述

> 面向大厨管家平台运营团队的 B 端管理后台，用于商家入驻审核、商品管理、价格规则配置、系统权限管理。

### 1.2 业务背景

- 解决运营人员在多个业务域（商家、商品、系统）中统一管理的需求
- 面向内部运营人员（非 C 端用户）
- B 端中后台，权限驱动，菜单由后端动态下发
- 后端服务通过 API 网关（`admin-api.dachuguanjia.com/admin-gateway/admin-app`）统一接入
- 前端采用微前端架构：主基座 `micro-main` 托管多个业务子应用

### 1.3 核心目标

- 运营人员能完成：商家入驻审核、商品上下架、价格规则配置、账号/角色/权限管理
- 前端职责：渲染菜单、路由鉴权、各子应用的业务页面、微前端通信
- **不承担**：C 端用户界面、移动端、数据分析平台、设计系统建设

### 1.4 非目标 / 边界

- 不负责服务端聚合逻辑（由 BFF/网关处理）
- 不负责移动端 / 小程序
- 不负责埋点分析平台本身（目前无埋点方案）
- 不负责设计系统建设（使用 dcgj-ui 封装层）

---

## 2. 用户与角色

### 2.1 主要用户类型

- **运营人员**：负责商家审核、商品管理、价格规则配置
- **系统管理员**：负责账号、角色、权限配置
- **超级管理员**：拥有全量菜单和操作权限

### 2.2 权限差异

权限由后端菜单系统驱动，差异体现在：

- **菜单可见性**：不同角色看到的侧边栏菜单不同
- **页面访问权限**：路由守卫根据用户权限列表判断
- **操作按钮权限**：<!-- TODO: 待确认 - 当前前端未见统一的按钮权限工具，各页面自行判断 -->

> 更细的角色和状态见 `03_BUSINESS_DOMAIN.md`。

---

## 3. 技术栈总览

### 3.0 当前项目采用情况

- 是否适用：**是**
- 本项目固定使用：
  - 框架：**Vue 3.2.x**（各 app 版本略有差异，app-system 已升至 Vue 3.5.x）
  - 构建工具：**Vite 2.7.x**（app-system 已升至 Vite 8.x，其他 app 仍用 2.7.x）
  - 路由方案：**Vue Router 4，Hash 模式**（`createWebHashHistory`）
  - 状态管理：**Pinia 2.x**（目录名各 app 不统一：`micro-main` 用 `store/`，子应用用 `stores/`）
  - UI 组件库：**dcgj-ui@0.0.11**（基于 ant-design-vue@4.2.6 封装，优先使用 dcgj-ui 组件，详见 `dcgj-components/`）
  - 语言：**TypeScript**（micro-main 用 TS 4.9.x，子应用用 TS 5.8.x）
  - 样式：**Sass（.scss）**
  - 微前端：**@micro-zoe/micro-app@1.0.0-rc.12**
  - 包管理：**pnpm@10.33.0**，monorepo workspace
- 禁止生成：
  - React 组件 / JSX
  - Element Plus / Naive UI / Arco Design
  - Redux / Vuex / Zustand
  - 裸 Axios 实例（必须通过 `@platform/http-client`）
  - History 模式路由
  - 跨 app 直接 import
- 与模板不同的地方：
  - 本项目是 **monorepo + 微前端**，每个 app 是独立子应用，不是单一 SPA
  - 没有 `features/` 层，业务组件放在各 app 的 `components/` 目录

### 3.1 前端基础栈

- 框架：Vue 3 + TypeScript
- 包管理器：pnpm（workspace monorepo）
- 构建工具：Vite
- 路由方案：Vue Router 4（Hash 模式）
- 状态管理：Pinia
- UI 组件库：dcgj-ui（ant-design-vue 封装）
- 样式方案：Sass（`.scss`）
- 请求库：`@platform/http-client`（Axios 封装）
- 测试方案：Vitest（`@platform/micro-bridge` 包内有测试，业务 app 暂无）
- 质量工具：ESLint v9 flat config + Prettier + Stylelint + Commitlint + Husky + lint-staged

### 3.2 关键配套能力

- 权限：后端菜单系统驱动，`micro-main` 的 `permission` store 管理
- 国际化：不适用（纯中文后台）
- 埋点：暂无
- 日志 / 监控：暂无（<!-- TODO: 待确认 -->）
- 灰度 / Feature Flag：暂无
- 设计 Token / 主题：基于 ant-design-vue token 系统，颜色通过 CSS 变量自定义（<!-- TODO: 确认主题配置位置 -->）

### 3.3 为什么选这套技术栈

- Vue 3 + Pinia：团队熟悉度
- 微前端（micro-app）：各业务子应用独立部署、独立发布
- dcgj-ui：基于 ant-design-vue 的内部封装，统一视觉与交互标准
- pnpm monorepo：共享 `@platform/*` 工具包，避免代码重复

---

## 4. 代码入口与关键目录

### 4.1 代码主入口（各 app）

| App | 入口 | 根组件 | 路由 | 状态 |
|-----|------|--------|------|------|
| `micro-main` | `src/main.ts` | `src/App.vue` | `src/router/index.ts` | `src/store/` |
| `app-merchant` | `src/main.ts` | `src/App.vue` | `src/router/index.ts` | `src/stores/` |
| `app-product` | `src/main.ts` | `src/App.vue` | `src/router/index.ts` | 无全局 store |
| `app-system` | `src/main.ts` | `src/App.vue` | `src/router/index.ts` | — |

### 4.2 关键目录速览（monorepo 根）

```text
dc-platform-new/
├── apps/
│   ├── micro-main/          # 主基座（端口 3000）
│   ├── app-system/          # 系统管理子应用（端口 3001，骨架阶段）
│   ├── app-merchant/        # 商家管理子应用（端口 3002）
│   ├── app-product/         # 商品中心子应用（端口 3003）
│   └── app-org-account/     # 组织账号子应用（开发中）
├── packages/
│   ├── shared-types/        # 公共 TS 类型（@platform/shared-types）
│   ├── shared-utils/        # 公共工具函数（@platform/shared-utils）
│   ├── http-client/         # HTTP 请求封装（@platform/http-client）
│   ├── auth-session/        # token 存储管理（@platform/auth-session）
│   └── micro-bridge/        # 微前端 IPC 协议（@platform/micro-bridge）
├── docs/                    # 项目文档（非 harness）
├── scripts/                 # 构建脚本
├── package.json             # root workspace
├── pnpm-workspace.yaml
├── tsconfig.base.json
├── eslint.config.mjs        # ESLint v9 flat config
└── .prettierrc.json
```

### 4.3 子应用内部典型目录（以 app-merchant 为例）

```text
apps/app-merchant/src/
├── api/                     # 接口请求 + types + mapper（按业务文件命名）
├── components/              # 当前 app 的业务/UI 组件
├── composables/             # Vue 3 composables
├── constants/               # 枚举和常量
├── micro/                   # 微前端 bridge 客户端
├── request/                 # HTTP client 初始化（调 @platform/http-client）
├── router/                  # 路由定义
├── stores/                  # Pinia stores（注意：micro-main 用 store/，子应用用 stores/）
├── types/                   # TS 类型定义
├── utils/                   # 工具函数
└── views/                   # 页面组件（路由级）
    └── merchant/
        ├── index.vue        # 页面容器
        ├── list.vue         # 列表页
        ├── detail.vue       # 详情页
        ├── form.vue         # 表单页
        └── audit.vue        # 审核页
```

### 4.4 关键配置文件

- TypeScript：`tsconfig.base.json`（root），各 app 下 `tsconfig.json` extends base
- 构建配置：各 app 的 `vite.config.ts`
- Lint：`eslint.config.mjs`（root，ESLint v9 flat config，使用 `@dcgj/eslint-config`）
- Format：`.prettierrc.json`
- 样式：`stylelint.config.js`
- 子应用 URL 配置：`apps/micro-main/src/config/domain.ts`（各子应用 URL 按环境配置）

---

## 5. 本地开发

### 5.1 环境要求

- Node 版本：建议 20.x（<!-- TODO: 确认最低 Node 版本要求 -->）
- 包管理器：pnpm@10.33.0（`corepack enable` 或手动安装）
- 浏览器：Chrome（现代版本）

### 5.2 安装依赖

```bash
pnpm install
```

### 5.3 本地启动

```bash
# 启动所有 app（并行，各自端口）
pnpm run dev

# 单独启动某个 app
pnpm --filter micro-main run dev        # 主基座 3000
pnpm --filter app-merchant run dev      # 商家管理 3002
pnpm --filter app-product run dev       # 商品中心 3003
pnpm --filter app-system run dev        # 系统管理 3001
```

本地完整开发流程（全量启动）：

1. `pnpm install`
2. `pnpm run dev`（启动所有 app）
3. 访问 `http://localhost:3000`（主基座）
4. 用测试账号登录（<!-- TODO: 补充测试账号获取方式 -->）
5. 子应用在主基座内以 iframe/micro-app 容器加载

### 5.4 常用命令

```bash
# 类型检查（所有 app）
pnpm run validate

# 代码检查
pnpm run lint
pnpm run lint:fix

# 样式检查
pnpm run stylelint

# 构建（生产）
pnpm run build:prod

# 构建（各环境）
pnpm run build:dev
pnpm run build:test
pnpm run build:pre

# 检查 app 间非法跨引用
pnpm run check:cross-app-references
```

---

## 6. 环境与配置

### 6.1 环境划分

- 本地：`.env.dev`（local ports，子应用 URL 指向 localhost）
- 测试：`.env.test`
- 预发：`.env.pre`
- 生产：`.env.prod`

### 6.2 关键环境变量

以 `micro-main` 为例：

| 变量 | 用途 | 必填 |
|------|------|------|
| `VITE_APP_PORT` | 本 app 端口（如 3000） | 是 |
| `VITE_APP_API_URL` | 后端 API base URL | 是 |
| `VITE_APP_BASE_API` | 代理 path 前缀（dev 用） | dev 时 |
| `VITE_APP_SYSTEM_URL` | app-system 子应用地址 | 是 |
| `VITE_APP_MERCHANT_URL` | app-merchant 子应用地址 | 是 |
| `VITE_APP_PRODUCT_URL` | app-product 子应用地址 | 是 |
| `VITE_BASE_URL` | 应用 base（通常 `/`） | 是 |

### 6.3 配置注入方式

- 构建时通过 Vite `import.meta.env` 注入
- 子应用 URL 集中在 `apps/micro-main/src/config/domain.ts` 按环境管理

---

## 7. 外部依赖与系统边界

### 7.1 对接系统

- **后端 API 网关**：`https://admin-api-{env}.dachuguanjia.com/admin-gateway/admin-app`
- **dcgj-ui 组件库**：内部 npm 包（`dcgj-ui@0.0.11`）
- **七牛云**：文件上传（`qiniu-js`）

### 7.2 边界说明

- 商家状态、商品状态的最终解释权在后端，前端仅做映射和展示
- 菜单/权限数据完全由后端下发，前端不做硬编码
- token 刷新逻辑在 `@platform/http-client` 和 `micro-main` 中处理，子应用通过 micro-bridge 请求主基座刷新
- 文件上传通过七牛云，前端直传，token 由后端接口提供

---

## 8. 发布与部署

- 构建产物：每个 app 独立 `dist/`，通过 Docker 打包（`Dockerfile`）
- Nginx 配置：`default.conf`
- 部署脚本：`deploy.bash`
- CI/CD：<!-- TODO: 确认 CI 平台 -->
- 回滚：<!-- TODO: 确认回滚流程 -->

---

## 9. 质量门槛与 Definition of Done

每个需求在前端侧完成前，至少满足：

- TypeScript 类型检查通过（`pnpm run validate`）
- lint 通过（`pnpm run lint`）
- 危险区域修改已完成自检（参考 `11_DANGEROUS_AREAS.md`）
- 核心流程本地自测通过
- 相关 docs 已更新

---

## 10. 真实性校验

- [x] 本文档中的项目名称、技术栈、启动命令来自真实项目
- [x] 本文档中的启动命令已验证可运行
- [x] 本文档中的依赖、环境变量与当前仓库一致
- [x] 本文档中的禁止技术栈已经明确写出
- [ ] 测试账号获取方式待补充
- [ ] CI/CD 链路待补充
- [ ] 回滚流程待补充
