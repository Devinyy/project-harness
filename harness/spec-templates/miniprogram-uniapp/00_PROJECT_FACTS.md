# 00_PROJECT_FACTS.md（模版骨架 · uni-app 多端 flavor）
> 🧩 A 精炼版：`<...>` 为占位符，按真实代码填充；固定常量已给出，仍需核对版本/路径。
---
owner: Frontend Team
last_verified: <生成时填写>
status: template
purpose: 项目事实速查（栈/命令/目录/认证/多端），agent 首先阅读这份
---

## 项目事实
- 项目：`<package.json name，例 ecm-welfare-app>`（<定位，如 多端福利商城>）
- 技术栈（固定）：**uni-app** + Vue 3（createSSRApp）+ TypeScript + Vite
- UI 库：**uview-plus**（全局 `app.use(uviewPlus)`，见 src/main.ts）
- 目标平台：`<例 H5 / 微信小程序(mp-weixin) / App>`，差异用 `#ifdef / #ifndef`
- 包管理器：`pnpm`（`<核对 script 是否用 npm run>`）
- 源码根 `src/`；别名 `@/* → src/*`
- 路由真相源 `src/pages.json`（+ src/router.ts）；平台清单 `src/manifest.json`
- 请求 `src/utils/request.ts`（基于 `<例 luch-request>`）；认证 `src/utils/auth.ts`；状态用 composable
- 启动 `<例 npm run dev:h5 / dev:mp-weixin / dev:app>`；构建 `<例 build:h5:test|prod / build:wx:* / build:app:*>`
- 类型检查 `<例 npm run lint:type>`（即 **vue-tsc --noEmit，不是 tsc**）；测试 `<核对；多为无单测，别假装 pnpm test>`
- lint `<例 npm run lint:ts / lint:css / lint:all>`
- 认证：token key `<例 user-auth>`；多租户/多渠道字段 `<填写>`；baseURL：src/config/env.ts / src/constants/config.ts，env `<填写>`

## 目录归属（真实目录）
- `src/pages/` 页面 `pages/<模块>/<xxx>-page.vue` ｜ `src/components/`（`basic/` 基础公共组件=危险区）
- `src/composables/` useXxx ｜ `src/api/`（一领域一文件，经 @/utils/request）｜ `src/utils/`（request/auth/router=危险区）
- `src/types/ config/ constants/ oauth2/ mixin/ static/ uni_modules/`
- 新增页面必须登记 `src/pages.json`；禁建 `services/ shared/ stores/ router/`

## 硬规则（固定）
- 禁 React/Ant Design/非 uview-plus UI 库；禁裸 luch-request/uni.request（走 src/api/*→@/utils/request）
- 多端差异用 #ifdef/#ifndef；固定 UI 图标用 <image> 引 src/static；动态内容图 <image :src> 绑数据+占位
- padding 块必须 box-sizing: border-box；危险区详见 11_DANGEROUS_AREAS.md
