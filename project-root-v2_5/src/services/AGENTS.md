# AGENTS.md — src/services/

本目录存放 API 调用层，按业务领域组织。

## 规则

- 一个领域一个文件：`userService.ts`、`orderService.ts`
- 函数命名：`getXxx` / `createXxx` / `updateXxx` / `deleteXxx`
- 返回类型必须显式定义（DTO 类型在同目录 `types/` 下）
- 错误处理在 service 层统一，不要让页面处理 HTTP 细节
- DTO → ViewModel 转换用 adapter 函数，不在页面里做
- 新增 service 前查看现有文件，遵循已有命名风格
