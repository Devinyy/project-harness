# 11_DANGEROUS_AREAS.md

> 🧩 模版骨架（A 精炼版）：保留结构，正文按真实代码填充；拿不准标 `// TODO: 待确认`，禁止编造。

---
owner: Frontend Team
last_verified: <生成时填写>
status: template
purpose: 危险区：改动成本高、影响面大的区域（PC 微前端）
---

## 1. 风险分级
<填写：P0 关键基础设施 / P1 高影响公共 / P2 中风险共享>

## 2. 危险区清单（每项：路径 + 为什么危险 + 改动前必做 + 红线）
### 2.1 基座启动链路（P0）
<填写：apps/micro-main/src/{main.ts,App.vue,bootstrap/}>

### 2.2 微前端注册与通信（P0）
<填写：micro/{registry,runtime,start}、config/domain、views/micro-app/、packages/micro-bridge>

### 2.3 认证与 Token（P0）
<填写：request/、tokenProvider、localStorage key、client_platform、401/471 refresh>

### 2.4 路由与权限守卫（P0）
<填写：router/、permission、store/modules/{permission,user}、Hash 模式、动态路由生成时机>

### 2.5 http-client 拦截器（P0）
<填写：packages/http-client（被所有 app 依赖）>

### 2.6 @platform/* 共享包（P0/P1）
<填写：shared-types/shared-utils/auth-session 向后兼容>

### 2.7 构建与工程配置（P0）
<填写：vite.config、pnpm-workspace、tsconfig.base、eslint/prettier、.env>

## 3. 修改前必做 / 红线 / 回归范围
<填写：影响面盘点、调用方、回滚、自测：登录/刷新/多角色/子应用挂载/请求链路>

> 机器可读清单见同目录 dangerous-zones.txt（驱动 hooks）。
