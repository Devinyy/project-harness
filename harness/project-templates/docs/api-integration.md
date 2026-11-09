---
owner: Harness Knowledge System
status: template
purpose: 记录 API 联调、契约匹配和失败边界
source: 项目 API specs、前后端接口、网络/服务日志和可重跑请求
maintained_when: 字段、错误码、鉴权、分页、环境或服务行为变化时
---

# API integration evidence

前端接口结构和 DTO 规则引用项目 `docs/specs/07_API_CONTRACTS.md`；本文件只记录本次联调证据，不复制公共契约正文。

## 联调记录

```text
ID: API-<稳定编号>
目标规则/模块: REQ-<编号> / <module>
接口/版本: <脱敏的 method + path + 版本>
仓库/提交: <前端、后端或网关仓库与 commit>
环境: <实际联调环境>
前提: <账号角色、数据和依赖服务>
请求/响应摘要: <不含秘密和客户原始数据的结构摘要>
错误/兼容边界: <已验证与未验证的错误码、分页、超时或降级>
命令/证据: <可重跑命令、截图或日志路径>
核对时间: {{DATE}}
实际结果: <观察到的结果>
状态: pass | fail | blocked | unverified
未验证范围: <未覆盖的字段、端、服务或权限>
```

不要因前端 mock、类型检查或本地构建通过而声称后端契约或生产接口通过。
