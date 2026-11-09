---
owner: pending
created_at: {{DATE}}
checked_at: pending
status: template
purpose: 记录当前实现、来源和未解决差距
source: 源码、配置、脚本、运行命令和项目前端 specs
maintained_when: 实现、依赖、接口、路由、权限或运行行为变化时
---

# 当前实现记录

本文件只描述“当前如何实现”，不把实现存在推定为用户已确认目标。前端领域事实优先引用项目 `docs/specs/`，尤其是 `00_PROJECT_FACTS.md`、`02_ARCHITECTURE.md`、`04_CODING_STANDARDS.md`、`06_UI_COMPONENT_GUIDE.md` 与 `07_API_CONTRACTS.md`；不要复制其中正文。

## 实现条目

```text
ID: IMPL-<稳定编号>
关联目标: REQ-<编号> | none
关联决策: ADR-<编号> | none
关联用例: CASE-<编号> | none
关联验收: QA-<编号> | none
创建时间: <实际创建时间，含时区>
核对时间: <实际核对时间，含时区；未核对写 pending>
范围: <系统/模块/入口>
实现状态: not-started | partial | observed | not-found
实现位置: <源码/配置/脚本路径与行号>
行为摘要: <由代码或运行证据确认的现状>
依赖/调用方: <已取证的依赖和影响范围>
来源: <提交、分支、命令、环境或项目 specs 路径>
差距: DEV-<编号> | none
未验证范围: <未运行的端、权限、数据或交互>
下一步: <实现者和行动>
```

源码、配置、运行证据冲突时保留冲突并标明新鲜来源；旧文档不能覆盖实测结果。实现变更后同步受影响的模块、用例、偏差和证据引用。
