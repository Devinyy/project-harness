# 05_COMPONENT_PATTERNS.md

> 🧩 模版骨架（A 精炼版）：保留结构，正文按真实代码填充；拿不准标 `// TODO: 待确认`，禁止编造。

---
owner: Frontend Team
last_verified: <生成时填写>
status: template
purpose: 组件拆分与复用模式、props/事件约定、状态选择
---

## 拆分原则

> 团队固定基线（不要按项目改写）：页面是「编排层」，不是「堆砌层」。拆分目的是可读 + 可复用；小程序自定义组件有 setData/通信开销，按下面触发条件拆，**不要无脑原子化**。

**何时必须拆子组件（命中任一即拆，可判定）**
- 单 `.vue` 文件 > ~500 行（硬信号；门禁 hook `check-large-file.sh` 会提示）
- `<template>` 顶层有 ≥3 个语义独立区块（头部 / 筛选 / 列表 / 弹窗）→ 每个区块抽 `src/components/<模块>/XxxSection.vue`
- 同一结构在模板里重复 ≥2 次 → 抽成组件
- `v-for` 的 item 模板 > ~30 行 → 抽 `XxxCard` / `XxxItem`
- 弹窗 / 抽屉 / 复杂表单 → 各自独立组件

**页面职责（只做编排）**
- 页面 = 取数（经 composable）+ 组合子组件 + 透传 props/事件，不堆细节 UI
- `<script setup>` 里的业务逻辑（状态/请求编排/计算）抽到 `src/composables/useXxxPage.ts`（ViewModel 层，见 `02_ARCHITECTURE.md` 通用分层模型）；页面 script 只剩「调 composable + 绑模板」
- 子组件放 `src/components/<模块>/`；`src/components/basic/` 是基础公共组件（危险区），别往里塞业务

**不要拆过头（小程序特有权衡）**
- 纯展示、无复用、< ~30 行的小段不必单独成组件——增样板、增 setData 通信、降可读
- 拆分单位是「语义区块 / 可复用单元」，不是「每个 div」

> 复用优先 ≠ 不许新建：**抽子组件不算「发明新架构」，是既有约定**，该拆就拆。

<填写：本项目已有的拆分约定/特例（如某模块固定的 Section 组件命名、特殊容器组件），无则删除本行>

## props / 事件约定
<填写：依据真实代码/配置提炼>

## 复用与封装
<填写：依据真实代码/配置提炼>

## 状态管理选择（local / composable·store）
<填写：依据真实代码/配置提炼>

## loading/empty/error 三态
<填写：依据真实代码/配置提炼>

