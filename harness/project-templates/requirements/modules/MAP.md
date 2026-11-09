---
owner: Harness Knowledge System
status: template
purpose: 维护需求模块实例的索引和追溯入口
source: requirements/confirmed-rules.md、模块文件和动态生成记录
maintained_when: 模块实例新增、移动、删除或关联变化时
---

# Requirement modules MAP

模块文件由显式 `--module <module>` 创建，源模板是 `requirements/modules/_module.md`。本 MAP 只登记实际生成的模块，不登记 `_module.md` 本身，也不预先编造模块名。

| 模块 | 入口 | 状态 |
| --- | --- | --- |
| `<module>` | `requirements/modules/<module>.md` | 按需生成后补充 |

模块文件建立后，初始化器在这里追加去重条目，并同步根 MAP；已有自定义内容必须保留。模块内通过规则 ID、实现路径、用例 ID 和偏差 ID 建立链路。
