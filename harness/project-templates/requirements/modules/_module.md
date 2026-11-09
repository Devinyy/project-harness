---
owner: Harness Knowledge System
status: template
purpose: 记录 {{MODULE}} 模块的目标、实现、用例和偏差引用
source: 已确认规则、源码/运行证据、验收用例和偏差记录
maintained_when: {{MODULE}} 的需求、实现、接口、验收或偏差变化时
---

# Module: {{MODULE}}

此文件只在显式提供安全模块名后生成。模块事实必须来自真实来源，模板本身不代表模块存在。

## 追溯入口

```text
模块: {{MODULE}}
规则 ID: RULE-<编号>（可多个）
需求 ID: REQ-<编号>
实现位置: <源码/配置路径与行号；或 {{ROOT}}harness/impl.md 与项目 docs/specs code 路径>
用例 ID: CASE-<编号>
偏差 ID: DEV-<编号> | none
证据: <{{ROOT}}docs/ 中的环境/接口/发布证据或可重跑命令>
核对时间: {{DATE}}
状态: not-started | partial | observed | not-found
验收结果: pass | fail | blocked | unverified
下一步: <明确行动和责任角色>
```

## 模块目标

<填写：引用 `requirements/confirmed-rules.md` 中的规则 ID；不要在这里复制目标正文。>

## 当前实现与边界

<填写：引用实现位置、项目 `docs/specs/` 事实和未验证范围；源码或运行证据优先于陈旧文档。>

## 用例与偏差

<填写：列出 CASE/DEV ID 和当前状态；修复与复验有新证据后再关闭偏差，不删除历史。>
