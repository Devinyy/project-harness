---
owner: pending
created_at: {{DATE}}
checked_at: pending
status: template
purpose: 记录已确认交互、视觉状态和验收边界
source: 用户确认需求、Figma/截图、前端 UI 指南和运行证据
maintained_when: 操作流程、状态、滚动/固定区或设备适配变化时
---

# Interaction constraints

只记录已确认或可取证的交互约束；没有设计输入时保持 `pending`，不从现有按钮推定目标。

## 交互条目

```text
ID: UX-<稳定编号>
目标规则: REQ-<编号> | none
创建时间: <实际创建时间，含时区>
核对时间: <实际核对时间，含时区；未核对写 pending>
设计来源: <Figma Frame/node、截图范围、PRD 或用户确认>
页面/模块: <项目路径或 module；没有写 pending>
目标状态: <loading/empty/error/normal/disabled/expanded/modal 等已确认状态>
操作与反馈: <用户操作、可见反馈、键盘/触屏可达性>
滚动/固定区域: <目标约束；未确认写 pending>
视口/端: <项目声明的基准、最小、宽屏或多端范围>
代码现状: <从源码/运行页面观察到的行为；不等同于目标>
验收用例: CASE-<编号> | none
确认状态: confirmed | pending | rejected | superseded
实现状态: not-started | partial | observed | not-found
验收结果: pass | fail | blocked | unverified
证据: <运行/截图/文件路径>
```

视觉验收引用项目 `docs/specs/06_UI_COMPONENT_GUIDE.md`、现有 token 和通用验收契约；不在模板中写项目专属尺寸或组件能力。
