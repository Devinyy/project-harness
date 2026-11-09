---
owner: pending
created_at: {{DATE}}
checked_at: pending
status: template
purpose: 记录仓库、提交、设备、账号和环境核对结果
source: Git、命令输出、运行地址、设备/账号和人工核对
maintained_when: 分支/提交、依赖环境、设备、账号或验证范围变化时
---

# Environment evidence

## 环境记录

```text
ID: ENV-<稳定编号>
仓库: <仓库名和路径>
分支/提交: <branch/commit；未提交写工作区状态>
环境: <local/CI/staging/production/其他实际环境>
地址/设备: <URL、设备、浏览器、端或模拟器；没有写 none>
账号/角色/数据: <仅记录必要角色和数据前提，不写秘密>
命令/操作: <可重跑命令或手工步骤>
创建时间: {{DATE}}
核对时间: <实际核对时间；未核对写 pending>
来源: <Git、平台输出、截图或命令日志路径>
实际结果: <观察到的结果>
证据结果: pass | fail | blocked | unverified
未验证范围: <未覆盖的端、权限、数据、页面或平台>
```

本地源码、构建成功和部署成功不能互相替代；生产状态必须有实际环境证据。敏感 token、密码、完整日志和客户数据不写入模板或普通记录。
