# dcgj-components/COMPONENT_INDEX.md（模版骨架）
> 🧩 列出本项目高频 dcgj-ui 组件及封装约定（DcgjTable/DcgjFormPro/DcgjDrawer…）。

| 组件 | 用途 | 约定/坑 |
|------|------|---------|
| `<Dcgj-xxx>` | <填写> | <填写：默认值/封装入口> |

## 组件发现与复核（固定规范）

初始化时从包管理器锁文件记录 `dcgj-ui` 的实际锁定版本，并检查包的类型声明/导出入口；再 grep 项目中的真实调用位置，确认组件在当前项目的组合方式。不能仅凭模板、旧文档或组件名称推断当前版本可用。

每个高频组件至少记录：

| 信息 | 取证来源 |
| --- | --- |
| 实际锁定版本 | lockfile + package.json overrides/resolutions |
| 组件与类型导出 | 当前安装包的类型声明或导出入口 |
| 真实调用位置 | 同 app 的 import 与模板调用 |
| 适用页面类型 | 列表 / 新建编辑 / 详情 / 弹层 |
| 使用边界 | Props、Slots、默认行为、状态与已知限制 |
| 复核信息 | 来源路径与最后复核日期 |

- dcgj-ui 官方组件优先；与 `06_UI_COMPONENT_GUIDE.md` 配合。
