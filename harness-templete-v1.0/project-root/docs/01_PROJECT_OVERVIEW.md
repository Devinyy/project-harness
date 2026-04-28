# 01_PROJECT_OVERVIEW.md

---
owner: Frontend Team
last_verified: 2026-04-21
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
  - 04_CODING_STANDARDS.md
  - 11_DANGEROUS_AREAS.md
---

> 使用说明：
>
> - 这是一份模板，请将 `<...>` 替换为项目真实信息
> - 对当前项目不适用的章节写 `N/A`
> - 尽量给出真实命令、真实目录和真实链接名，不要只写泛化描述
> - 本文档优先回答“这个项目是什么、怎么跑、依赖什么、哪些约束必须知道”

---

## 1. 项目基础信息

- 项目名称：`<Project Name>`
- 仓库名称：`<repo-name>`
- 仓库地址：`<repo-url>`
- 所属团队：`<team-name>`
- 维护负责人：`<owner>`
- 主要协作角色：
  - 产品：`<PM>`
  - 设计：`<Designer>`
  - 前端：`<FE Owner>`
  - 后端：`<BE Owner>`
  - 测试：`<QA Owner>`

### 1.1 一句话描述

用一句话说清楚本项目的核心作用：

> `<示例：面向商家运营后台的 Web 应用，用于商品管理、活动配置、订单查询与权限控制。>`

### 1.2 业务背景

说明项目为什么存在、服务哪些核心业务流程。

示例可覆盖：

- 解决什么业务问题
- 面向哪些角色
- 是否属于中后台 / C 端 / B 端 / 内部工具
- 与其他系统如何协作

### 1.3 核心目标

- 核心用户能完成哪些关键操作
- 前端承担哪些职责
- 本项目不承担哪些职责

### 1.4 非目标 / 边界

请明确以下内容：

- 本项目是否负责服务端聚合逻辑
- 是否负责复杂离线能力
- 是否负责埋点分析平台本身
- 是否负责设计系统建设
- 是否负责移动端、小程序、桌面端

---

## 2. 用户与角色

### 2.1 主要用户类型

列出使用本系统的核心角色：

- `<角色 A>`：负责什么
- `<角色 B>`：负责什么
- `<角色 C>`：负责什么

### 2.2 权限差异

说明角色差异体现在什么地方：

- 菜单可见性
- 页面访问权限
- 字段可编辑性
- 操作按钮权限
- 数据范围权限

> 更细的角色、术语、状态含义请写在 `03_BUSINESS_DOMAIN.md`，这里只做总览。

---

## 3. 技术栈总览

### 3.1 前端基础栈

- 框架：`<React / Vue / Next / Nuxt / 其他>`
- 语言：`<TypeScript / JavaScript>`
- 包管理器：`<pnpm / npm / yarn>`
- 构建工具：`<Vite / Webpack / Rspack / 其他>`
- 路由方案：`<React Router / Vue Router / 文件路由 / 其他>`
- 状态管理：`<Redux / Zustand / Pinia / Vuex / React Query / SWR / 其他>`
- UI 组件库：`<Ant Design / Element Plus / Arco / 自研组件库 / 其他>`
- 样式方案：`<CSS Modules / Sass / Tailwind / styled-components / Less / 其他>`
- 请求库：`<Axios / fetch 封装 / 其他>`
- 测试方案：`<Vitest / Jest / Cypress / Playwright / 其他>`
- 质量工具：`<ESLint / Prettier / Stylelint / Commitlint / Husky / 其他>`

### 3.2 关键配套能力

- 权限：`<方式>`
- 国际化：`<方式>`
- 埋点：`<方式>`
- 日志 / 监控：`<方式>`
- 灰度 / Feature Flag：`<方式>`
- 设计 Token / 主题：`<方式>`

### 3.3 为什么选这套技术栈

简要说明：

- 历史原因
- 团队熟悉度
- 生态依赖
- 性能、SSR、微前端、工程化等方面的考虑

---

## 4. 代码入口与关键目录

### 4.1 代码主入口

- 应用入口：`<src/main.ts | src/main.tsx | app.vue | pages/_app.tsx ...>`
- 根组件：`<src/App.vue | src/App.tsx | layouts/...>`
- 路由定义：`<src/router | src/routes>`
- 全局 Provider / 插件注册：`<path>`
- 全局样式入口：`<path>`

### 4.2 关键目录速览

```text
<repo-root>/
├── src/
│   ├── app/                # 应用壳层、provider、全局初始化
│   ├── pages/              # 路由级页面
│   ├── features/           # 模块内业务组件和逻辑
│   ├── shared/             # 可跨模块复用的通用能力
│   ├── services/           # API service / 请求封装
│   ├── store/              # 全局或共享状态
│   ├── hooks/              # hooks / composables
│   ├── utils/              # 工具函数
│   ├── styles/             # 全局样式 / token
│   └── constants/          # 常量与枚举
├── docs/                   # 项目文档
├── public/                 # 静态资源
├── scripts/                # 工程脚本
└── package.json
```

> 请根据真实项目目录调整，避免模板内容与仓库不一致。

### 4.3 关键配置文件

- TypeScript：`<tsconfig.json>`
- 构建配置：`<vite.config.ts | webpack.config.js | next.config.js>`
- Lint：`<.eslintrc.*>`
- Format：`<.prettierrc.*>`
- 样式配置：`<tailwind.config.js | postcss.config.js | stylelint>`
- 测试配置：`<vitest.config.ts | jest.config.js | playwright.config.ts>`

---

## 5. 本地开发

### 5.1 环境要求

- Node 版本：`<version>`
- 包管理器版本：`<version>`
- 浏览器要求：`<Chrome 版本 / 兼容策略>`
- 其他依赖：`<如 pnpm workspace、nvm、volta、corepack 等>`

### 5.2 安装依赖

```bash
<package-manager> install
```

### 5.3 本地启动

```bash
<package-manager> run dev
```

如有多个启动命令，请分场景说明：

- 本地开发：`<command>`
- 联调环境：`<command>`
- 指定模块：`<command>`
- Mock 模式：`<command>`

### 5.4 常用命令

```bash
# 类型检查
<package-manager> run typecheck

# 代码检查
<package-manager> run lint

# 单元测试
<package-manager> run test

# 构建
<package-manager> run build
```

### 5.5 本地开发的最短路径

建议写出从 0 到 1 的最短操作步骤，例如：

1. 安装依赖
2. 复制环境变量
3. 启动开发服务
4. 打开指定本地地址
5. 使用测试账号登录
6. 进入某个示例页面验证应用正常

---

## 6. 环境与配置

### 6.1 环境划分

- 本地：`local`
- 开发：`dev`
- 测试：`test / staging`
- 预发：`pre`
- 生产：`prod`

### 6.2 环境变量

请列出关键环境变量，不要只写“参考 .env”。

示例：

- `VITE_API_BASE_URL`：后端 API 基础地址
- `VITE_APP_ENV`：当前运行环境标识
- `VITE_SENTRY_DSN`：异常监控配置
- `VITE_ENABLE_MOCK`：是否启用 Mock
- `VITE_FEATURE_X_ENABLED`：特性开关

对每个变量说明：

- 用途
- 是否必填
- 默认值
- 错误配置的表现
- 是否影响打包结果

### 6.3 配置注入方式

- 构建时注入还是运行时注入
- CI/CD 如何提供
- 本地如何覆盖
- 敏感配置如何管理

> 不要在文档中写入真实密钥、Token 或内部敏感信息。

---

## 7. 外部依赖与系统边界

### 7.1 对接系统

列出前端需要依赖的外部系统：

- 认证系统
- 后端网关 / BFF
- 设计系统 / 组件库
- 文件上传服务
- 日志与监控服务
- 埋点平台
- 权限中心
- 国际化平台

### 7.2 边界说明

请明确：

- 哪些数据由后端提供，前端不做业务真值判断
- 哪些字段或状态只能由后端解释
- 哪些能力依赖第三方，前端只负责接入
- 哪些能力由网关/BFF 统一处理，不应在页面重复实现

---

## 8. 发布与部署

### 8.1 发布链路

- 代码合并到哪个分支后触发什么流程
- 构建由哪个 CI 平台执行
- 产物发布到哪里
- 是否支持灰度
- 是否区分多租户 / 多环境 / 多站点

### 8.2 发布前检查

发布前至少确认：

- 类型检查通过
- lint 通过
- 核心流程自测通过
- 环境变量正确
- Feature Flag 状态正确
- 埋点 / 权限 / 国际化未遗漏
- 相关 docs 已更新

### 8.3 回滚方式

请记录：

- 回滚入口
- 回滚粒度
- 是否支持热修复 / 快速回退
- 发生线上异常时联系谁

---

## 9. 质量门槛与 Definition of Done

每个需求在前端侧完成前，至少满足：

- 代码符合 `04_CODING_STANDARDS.md`
- 结构符合 `02_ARCHITECTURE.md`
- UI 选型符合 `06_UI_COMPONENT_GUIDE.md`
- API 处理符合 `07_API_CONTRACTS.md`
- 危险区域修改已完成自检
- 复杂需求已完成技术方案
- 必要文档已更新
- 自测记录完整

---

## 10. 新成员必读提示

### 上手建议

第一次进入项目时，建议先完成：

1. 跑通本地环境
2. 熟悉路由和主要页面
3. 阅读 `02`、`03`、`04`、`06`、`07`
4. 查看一个已完成模块的代码路径
5. 完成一个小需求或低风险 bug 修复


---

## 11. 建议补充的项目真实信息清单

为避免这份总览停留在模板层，建议尽快补全：

- 真实项目名与一句话描述
- 真实目录结构与入口文件
- 真实技术栈版本
- 真实启动命令和测试账号获取方式
- 真实环境变量说明
- 真实 CI/CD 与部署链路
- 真实外部依赖系统名单
- 真实回滚联系人与流程

---

## 12. 最后提醒

`01_PROJECT_OVERVIEW.md` 的职责是让人和 AI 在 5~10 分钟内建立“全局认知”。

它不替代架构文档、业务文档和编码规范；
但如果这份文档缺失或过时，后续所有开发都会更依赖猜测、更容易走偏。
