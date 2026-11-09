---
owner: Harness Knowledge System
status: template
purpose: 记录发布、访问、回滚和事故核对证据
source: 发布平台、部署提交、实际站点/服务访问和回滚记录
maintained_when: 发布、回滚、热修复或线上状态变化时
---

# Release / rollback evidence

## 发布记录

```text
ID: RELEASE-<稳定编号>
目标/范围: REQ-<编号> / <模块或版本>
来源仓库: <发布提交对应的仓库和路径>
发布提交/构建: <commit、构建号或制品>
目标环境: <staging/production/其他实际环境>
授权/发布角色: <明确授权来源和执行角色>
发布时间: <实际时间；计划时间不能代替>
核对时间: <实际核对时间；与发布时间分开记录>
验证操作: <站点访问、主要功能、接口、监控或回滚检查>
实际结果: <观察到的结果>
回滚方案/证据: <触发条件、命令、制品或实际回滚结果>
发布状态: planned | released | rolled-back | blocked
证据结果: pass | fail | blocked | unverified
来源: <平台输出、访问记录、截图或日志路径>
未验证范围: <未覆盖的功能、端、权限、流量或监控>
下一步: <责任角色和行动>
```

本地代码、构建成功或“部署完成”消息不能单独证明站点可达、业务通过或回滚成功。发布/回滚仍需对应授权，记录流程不等于授权操作。
