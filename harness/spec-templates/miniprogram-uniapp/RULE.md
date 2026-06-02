# Flavor 规则：uni-app 多端类（如 ecm-welfare）

适用：uni-app + Vue 3（createSSRApp）+ uview-plus，多端 H5/微信小程序/App。具体值必须从当前仓库取证。

## 探索重点
- package.json：scripts（dev:h5/dev:mp-weixin/dev:app、build:*、lint:type=vue-tsc、lint:ts/lint:css）、依赖（@dcloudio/uni-app、uview-plus、luch-request）、包管理器
- src/pages.json（路由真相源+分包）、src/manifest.json（各平台 AppID/权限/SDK）
- src/main.ts（createSSRApp + app.use(uviewPlus)）、src/App.vue、src/router.ts（守卫）
- src/utils/：request.ts（封装+拦截器+401刷新）、auth.ts（Token/AuthState/Channel）、router.ts
- src/api/（按领域）、src/composables/（useXxx）、src/components/basic/（基础公共组件）
- src/config/env.ts、src/constants/config.ts（baseURL）、src/oauth2/、src/mixin/、src/uni.scss
- 多租户/多渠道分流与时序

## 各文档要点
- 00：栈=uni-app+Vue3(createSSRApp)+Vite+uview-plus；多端 #ifdef；命令 npm run dev:* / build:* / lint:type(vue-tsc，不是 tsc) / **无单测**；别名 @→src；token key、baseURL env。禁止：React/Ant Design、裸 luch-request/uni.request（走 src/api/*→@/utils/request）、建 services/shared/stores/router 目录、把固定 UI 图标用 emoji/CSS 替代、把动态内容图当静态切图。
- 04：含「样式」一节——padding 块必须 `box-sizing: border-box`（check-box-sizing hook 校验）。
- 06：uview-plus 优先；含「Figma 切图/图片素材」——固定 UI chrome 才切图用 <image> 引 src/static，动态内容图(商品/Banner/logo/分类图标/富文本)一律 <image :src="vm.xxxUrl"> 绑数据+占位兜底。
- 11：P0=请求封装/拦截器、认证/Token、应用入口、全局路由守卫、pages.json、manifest.json、环境/baseURL；P1=uni.scss、components/basic/、oauth2/、uni_modules/。

## dangerous-zones.txt：见同目录模版，按实际增删。
## 目录级 AGENTS：src/api、src/components、src/composables、src/utils。
## 类型检查：pnpm exec vue-tsc --noEmit（等价 npm run lint:type）。Stop hook 不要调 pnpm test（无单测）。
