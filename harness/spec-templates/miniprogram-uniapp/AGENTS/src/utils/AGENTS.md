# AGENTS.md — src/utils/（模版 · ⚠️ 基础设施危险区）
request.ts/auth.ts/router.ts 等。见 docs/specs/11_DANGEROUS_AREAS.md。
- 禁为单页面需求改 request.ts/auth.ts；改拦截器/token 要全端(H5/小程序/App)回归
