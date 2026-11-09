---
owner: pending
created_at: {{DATE}}
checked_at: pending
status: template
purpose: 已有失败、风险和修复闭环的案例导航
source: 实际失败证据、QA 记录、用户反馈和复验结果
maintained_when: 案例新增、修复、复验或关闭时
---

# Badcase MAP

本域只登记有实际证据的失败案例。`_case.md` 是源模板，不是业务案例；初始化器只有在显式提供 `--case` 时才生成 `badcase/<case>.md`。

| 案例 ID | 文件 | 问题状态 | 验收结果 | 下一步 |
| --- | --- | --- | --- | --- |
| `<CASE-...>` | `badcase/<case>.md` | `<open | in-fix | recheck | closed | blocked>` | `<pass | fail | blocked | unverified>` | `<负责人/动作>` |

案例必须关联需求/模块、用例、偏差和证据；修复后追加修复与复验证据，关闭不删除历史。未实例化的案例不建立 Markdown 链接。
