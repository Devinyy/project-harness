# AGENTS.md — packages/（模版 · ⚠️ @platform/* 共享包危险区）
被所有 app 依赖，影响面极大。
- 禁为单页面/单 app 改此目录；修改前必读 docs/specs/11_DANGEROUS_AREAS.md
- http-client 拦截器改动全 app 验证，扩展走 option/callback
- micro-bridge 改 IPC 事件名同步双端；shared-types 改基础类型向后兼容
- 新增共享包需评审；改动列使用方与回归范围
