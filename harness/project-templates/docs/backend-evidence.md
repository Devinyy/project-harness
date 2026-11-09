---
owner: Harness Knowledge System
status: template
purpose: 记录后端、网关、跨仓库和服务环境证据
source: 后端仓库、服务日志、平台输出、接口响应和环境核对
maintained_when: 后端实现、网关路由、服务版本或跨仓库依赖变化时
---

# Backend / cross-repository evidence

## 证据记录

```text
ID: BACKEND-<稳定编号>
关联目标/接口/模块: REQ-<编号> / API-<编号> / <module>
来源仓库/服务: <名称、路径或服务标识>
分支/提交/版本: <可追溯版本>
环境: <实际环境；没有写 blocked>
核对时间: {{DATE}}
证据来源: <命令、平台输出、日志、响应或截图路径>
实际结果: <观察到的服务/网关/数据结果>
与前端影响: <字段、错误码、时序、权限或兼容影响>
状态: pass | fail | blocked | unverified
未验证范围: <未覆盖的服务、数据、端或生产状态>
下一步: <责任角色和行动>
```

后端证据不能由前端源码或本地构建推定；敏感日志和秘密只保留受控证据引用。
