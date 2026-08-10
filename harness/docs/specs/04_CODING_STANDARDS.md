# 04_CODING_STANDARDS.md

> 🧩 模版骨架（A 精炼版）：保留结构，正文按真实代码填充；拿不准标 `// TODO: 待确认`，禁止编造。

---
owner: Frontend Team
last_verified: <生成时填写>
status: template
purpose: 命名、类型约束、样式、错误处理与提交规范
---

## 总体原则
<填写：依据真实代码/配置提炼>

## 命名规范
<填写：依据真实代码/配置提炼>

## 类型约束（不留 any）
<填写：依据真实代码/配置提炼>

## 样式规范
<填写：依据真实代码/配置提炼>

### PC 视觉 Token 约束

- PC 页面新增或调整颜色、字号、背景、边框时，优先匹配 `docs/token-specs/Light.tokens.json` 与 `docs/token-specs/antd-vue-theme.ts`。
- 禁止为局部 UI 还原随意硬编码 token 外色号、字号；确需新增时先标 `// TODO: 待确认设计 token`。
- 业务 CSS 变量可以保留业务前缀，但变量值必须能追溯到 `docs/token-specs/`。

## 错误处理
<填写：依据真实代码/配置提炼>

## 提交规范（Conventional Commits）
<填写：依据真实代码/配置提炼>
