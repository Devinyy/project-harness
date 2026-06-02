# 11_DANGEROUS_AREAS.md

> 🧩 模版骨架（A 精炼版）：保留结构，正文按真实代码填充；拿不准标 `// TODO: 待确认`，禁止编造。

---
owner: Frontend Team
last_verified: <生成时填写>
status: template
purpose: 危险区：改动成本高、影响面大的区域（uni-app 多端）
---

## 1. 风险分级
<填写：P0 / P1 / P2>

## 2. 危险区清单（每项：路径 + 为什么危险 + 改动前必做 + 红线）
### 2.1 请求封装与拦截器（P0）
<填写：src/utils/request.ts，401 刷新、影响所有接口>

### 2.2 认证 / Token（P0）
<填写：src/utils/auth.ts，Token/AuthState/UserInfo/Channel、localStorage key>

### 2.3 应用入口与全局路由（P0）
<填写：src/main.ts、src/App.vue、src/router.ts 守卫、src/mixin/>

### 2.4 页面注册与平台清单（P0）
<填写：src/pages.json（路由真相源）、src/manifest.json（各平台 AppID/权限/SDK）>

### 2.5 环境 / baseURL（P0）
<填写：src/config/、src/constants/config>

### 2.6 全局样式 / 基础组件 / 三方（P1）
<填写：src/uni.scss、src/components/basic/、src/oauth2/、src/uni_modules/>

## 3. 修改前必做 / 红线 / 回归范围
<填写：影响面盘点、调用方、回滚、自测：登录/多端(H5·小程序·App)/多租户多渠道/核心页面>

> 机器可读清单见同目录 dangerous-zones.txt（驱动 hooks）。
