---
owner: Harness Knowledge System
status: template
purpose: 维护跨领域术语、字段和改名同步规则
source: 已确认需求、接口契约、源码调用和团队命名规则
maintained_when: 新术语、字段改名、模块重命名或跨端差异出现时
---

# Naming / 术语与改名记录

本文件记录跨领域的稳定术语和同步责任，不复制前端命名细节。前端命名与样式规则引用项目 `docs/specs/04_CODING_STANDARDS.md`；接口字段引用项目 `docs/specs/07_API_CONTRACTS.md`。

## 术语条目

```text
TERM: TERM-<稳定编号>
规范名称: <跨领域名称>
允许别名: <仅在来源中存在的别名；没有写 none>
禁止混用: <容易混淆的名称>
来源: <需求/接口/源码/决策引用>
适用范围: <系统/模块/端>
状态: current | pending | retired
```

## 改名同步清单

```text
RENAME: RENAME-<稳定编号>
旧名称: <名称>
新名称: <名称>
目标/决策: REQ-<编号> | ADR-<编号>
受影响代码: <源码、路由、API、配置和调用方>
受影响资料: <modules、impl、test-spec、deviations、docs/specs 等路径>
操作顺序: <先兼容/迁移/更新引用的顺序>
验收用例: CASE-<编号>
下一步/责任: <角色和时间>
```

改名不能只改文档中的一处；完成后核对代码、接口、测试、前端 specs 和 MAP 引用。
