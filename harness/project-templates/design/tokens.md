---
owner: Harness Knowledge System
status: template
purpose: 记录 token 来源、适用范围和核对状态，不复制 token 值
source: 项目 docs/token-specs、前端 UI 指南、设计系统和运行页面
maintained_when: token 来源、版本、主题或视觉验收基线变化时
---

# Design tokens

token 值只维护在目标项目已有的 `docs/token-specs/` 或其明确设计系统中；本模板不复制色号、字号、间距或主题正文。前端组件使用方式引用项目 `docs/specs/06_UI_COMPONENT_GUIDE.md`。

## 来源记录

```text
ID: TOKEN-<稳定编号>
来源路径/系统: <项目 token 文件、设计系统或 Figma 引用>
版本/提交: <可追溯版本；没有写 unverified>
主题/端: <主题、端或视口>
目标用途: <已确认的设计约束>
代码提取值: <从当前实现观察到的引用；不要把它写成目标>
核对时间: {{DATE}}
证据: <截图、运行页面、构建或文件引用>
状态: confirmed | pending | observed | unverified
未验证范围: <组件、主题、端或视口>
```

发生设计与代码冲突时保留两者，分别记录目标和现状；视觉验收按项目根 `docs/harness/verification.md` 和前端 UI 指南执行。
