---
owner: pending
created_at: {{DATE}}
checked_at: pending
status: template
purpose: 键盘、焦点和快捷键行为的证据记录
source: 交互目标、浏览器/设备观察、自动化输出和 QA 结果
maintained_when: 键盘或焦点行为、可访问性约束或端差异变化时
---

# Keyboard and focus events

- 需求/模块 ID：`<REQ-...>` / `<模块 ID 或 none>`
- 用例 ID：`<CASE-...>`
- 端/设备/浏览器：`<实际值>`
- 创建时间（UTC）：{{DATE}}
- 核对时间（UTC）：`<实际核对时间；未核对写 pending>`
- 目标交互来源：`<PRD/Figma/项目 docs/specs 路径>`

## 事件记录

| 步骤 | 输入/事件 | 焦点或选中状态 | 实际结果 | 证据 |
| --- | --- | --- | --- | --- |
| 1 | `<待填>` | `<待填>` | `<pending>` | `<路径或 none>` |

## 边界与后续

- 覆盖范围：`<桌面/移动/键盘布局等>`
- 未覆盖范围：`<明确写出>`
- 偏差 ID：`<DEV-... 或 none>`
- 实现状态：`<not-started | partial | observed | not-found>`
- 验收结果：`<pass | fail | blocked | unverified>`
- 修复与复验：`<证据路径或 pending>`

前端组件和 token 约束只引用项目根 `docs/specs/06_UI_COMPONENT_GUIDE.md` 与 `docs/token-specs/`；公共验收触发和独立 QA 规则只引用 `docs/harness/verification.md`。
