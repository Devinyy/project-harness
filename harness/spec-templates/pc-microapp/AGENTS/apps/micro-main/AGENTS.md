# AGENTS.md — apps/micro-main/（模版 · ⚠️ 基座危险区）
启动链路/路由/权限守卫/micro 注册与通信/token/全局壳。改错全站白屏/登录失效/子应用挂不上。
- 修改前必读 docs/specs/11_DANGEROUS_AREAS.md
- 不在守卫加局部业务；不改 token key；不改 Hash→History
- 改 micro runtime 暴露方法签名要同步 micro-bridge 与子应用双端
- P0：盘点影响面→列调用方→写回滚→自测登录/刷新/多角色/子应用
