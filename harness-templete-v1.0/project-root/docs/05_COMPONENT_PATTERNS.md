# 05_COMPONENT_PATTERNS.md

---
owner: Frontend Team
last_verified: 2026-04-21
status: active
purpose: 沉淀组件分层、目录组织、页面骨架、表单/列表/弹层等常见实现模式，帮助开发者快速复用成熟方案。
primary_readers:
  - Frontend Developers
  - AI Agents
related:
  - 02_ARCHITECTURE.md
  - 04_CODING_STANDARDS.md
  - 06_UI_COMPONENT_GUIDE.md
  - 08_TASK_PLAYBOOKS.md
  - 11_DANGEROUS_AREAS.md
---

> 使用说明：
>
> - 本文件强调“怎么组织组件与逻辑”
> - `06_UI_COMPONENT_GUIDE.md` 负责“选什么 UI”，本文件负责“怎么拆、怎么放、怎么复用”
> - 不要把单次历史实现误写成项目通用模式

---

## 1. 组件模式目标

组件模式的目标不是制造更多抽象，而是：

1. 让相似页面和模块具备一致的结构
2. 让新增需求先复用已有模式
3. 让页面层保持轻量，避免“一个页面做完所有事”
4. 让新增代码能通过目录和命名保持同风格

---

## 2. 组件分层

推荐按以下四层理解组件：

### 2.1 Page 组件

职责：

- 路由入口
- 页面级数据请求和流程编排
- 组合多个业务组件
- 接入权限、埋点、页面级状态恢复

不应承担：

- 可跨页面复用的通用组件实现
- 大量字段转换逻辑
- 深层局部交互细节

### 2.2 Feature 组件

职责：

- 当前业务模块内的复合组件
- 模块内筛选栏、列表、详情块、操作区、表单块
- 局部 hooks / composables 的消费方

特征：

- 带业务语义
- 可读页面上下文
- 不应直接污染全局

### 2.3 Shared Business 组件

职责：

- 跨多个模块复用的业务组件
- 兼具业务语义与相对稳定的交互模式

示例：

- `SearchFilterBar`
- `PermissionGuard`
- `EntityStatusTag`
- `DateRangeFilter`

### 2.4 Base UI 组件

职责：

- 基础视觉与交互能力
- 对第三方 UI 库的统一封装
- 通用容器、按钮、输入框、表格、标签、弹层

> 细节选型规则见 `06_UI_COMPONENT_GUIDE.md`

---

## 3. 目录组织建议

请根据真实项目栈调整，推荐如下：

```text
src/
├── pages/
│   └── merchant/
│       ├── ListPage.tsx
│       └── DetailPage.tsx
├── features/
│   └── merchant/
│       ├── components/
│       ├── hooks/
│       ├── utils/
│       ├── constants/
│       └── types.ts
├── shared/
│   ├── ui/
│   ├── business/
│   ├── hooks/
│   └── utils/
```

### 3.1 单文件还是文件夹

建议：

- 结构简单、逻辑少：单文件组件
- 结构复杂、带样式/测试/子组件：文件夹组件
- 当一个组件已经包含以下 2 项以上时，建议升级为文件夹：
  - 独立样式
  - 独立类型
  - 多个子组件
  - 本地 hooks
  - 测试文件
  - story / demo

### 3.2 推荐组件文件夹结构

```text
MerchantFilter/
├── index.ts
├── MerchantFilter.tsx
├── types.ts
├── constants.ts
├── hooks.ts
└── styles.module.less
```

如项目采用 Vue，可调整为：

```text
MerchantFilter/
├── index.ts
├── MerchantFilter.vue
├── useMerchantFilter.ts
├── types.ts
└── constants.ts
```

---

## 4. 何时拆组件

满足以下任一条件时，建议拆组件：

- 某一块 UI 可独立命名且职责清晰
- 同类结构在页面中重复两次以上
- 模板 / JSX 长度明显过长
- 某一块逻辑有独立状态与交互
- 某一区块将来可能被复用

不要为了“看起来模块化”而机械拆分极小组件，导致阅读困难。

---

## 5. 容器组件与展示组件

如果项目适合，可以保留以下分工：

- 容器组件：
  - 负责取数、状态编排、事件处理
- 展示组件：
  - 负责接收数据并渲染 UI

但不要过度形式化。判断标准：

- 是否真的有复用价值
- 是否能明显降低耦合
- 是否会让调用链更清晰

不推荐：

- 为了套模式把所有组件都拆成 `Container + View`
- 展示组件 props 过多，反而更难维护

---

## 6. Props / Events 设计模式

### 6.1 Props 设计

- props 数量控制在必要范围
- 优先传递语义化数据，不传过多原始碎片字段
- 互斥行为不要依赖多个布尔组合
- 复杂配置优先对象配置，但要有清晰类型

### 6.2 事件设计

- 事件名体现业务动作，如 `onSubmitSuccess`、`onStatusChange`
- 回调参数类型清晰
- 不要通过一个 `onChange` 承载多个完全不同语义的动作

### 6.3 默认值与可选项

- 默认值应与项目主流场景一致
- 高风险行为不要靠默认值隐式开启
- 组件对外暴露的选项越少越稳定

---

## 7. 页面级模式

### 7.1 列表页模式

推荐结构：

1. PageHeader
2. FilterArea
3. Toolbar / BatchActionArea
4. Table / List
5. Pagination
6. DetailDrawer / Modal（可选）

列表页应明确：

- 查询条件放哪里
- 分页放哪里
- 列定义放哪里
- 批量操作放哪里
- 刷新时机是什么

### 7.2 详情页模式

推荐结构：

1. Header
2. Summary
3. Section Blocks
4. Timeline / Log（可选）
5. Sticky Action Footer（可选）

详情页应明确：

- 首屏关键字段
- 是否支持编辑态切换
- 子模块是否拆成 section component
- 返回列表时是否恢复上下文

### 7.3 创建 / 编辑页模式

推荐结构：

1. Header / Steps
2. Basic Info Form
3. Advanced Settings
4. Validation / Preview
5. Footer Actions

应明确：

- 草稿是否保存
- 校验时机
- 提交成功后跳转哪里
- 表单状态谁管理
- 大表单是否拆成多个块组件

---

## 8. 弹层模式

### 8.1 Modal 模式

适合：

- 短表单
- 确认类操作
- 需要用户集中注意力的轻流程

推荐组件拆分：

- `XxxDialog`
- `XxxDialogForm`
- `useXxxDialog`

### 8.2 Drawer 模式

适合：

- 中长表单
- 需要保留主页面上下文
- 详情查看 + 局部编辑

### 8.3 弹层状态管理

建议：

- 开关状态放在最近的拥有者
- 弹层提交成功后的刷新策略明确
- 多层弹层尽量避免
- 打开时初始化、关闭时重置逻辑可预期

---

## 9. 表单模式

### 9.1 表单组件分层

- Page / Feature：组织表单流程与提交
- Form Section：一组相关字段
- Field Wrapper：项目通用字段包装
- Base Input：基础输入组件

### 9.2 表单状态归属

- 临时输入：表单库 / local state
- 提交后的共享结果：store 或父级状态
- 异步字典项：service + 缓存策略

### 9.3 校验模式

明确：

- 实时校验 vs 提交校验
- 跨字段校验放哪里
- 后端返回字段错误如何映射
- 大表单分段校验如何处理

---

## 10. 表格模式

建议将表格相关内容拆清楚：

- 列定义：`columns.ts` / `useColumns.ts`
- 查询条件：`Filter.tsx`
- 行操作：`RowActions.tsx`
- 批量操作：`BatchActions.tsx`
- 状态标签：`StatusTag.tsx`

不建议：

- 所有列 render 都堆在页面组件里
- 在列定义中塞入大量业务计算与请求逻辑
- 行操作直接修改全局状态却没有清晰入口

---

## 11. hooks / composables 模式

推荐用途：

- 列定义生成
- 查询条件同步
- 弹层开关与状态初始化
- 表格请求逻辑复用
- 表单预填与重置
- 权限判断辅助

不适合：

- 只被调用一次、且没有复用价值的逻辑
- 复杂业务流程全部塞进一个 hook
- hook 输出过大、职责模糊

---

## 12. 何时抽共享组件

只有同时满足以下条件，才建议抽到 shared：

- 至少在两个模块中真实复用
- 抽象后的命名自然清晰
- 不需要依赖单模块上下文
- 未来变更不会被一个模块绑架

否则优先保持在 feature 内，延迟抽象。

---

## 13. 何时新增业务组件

满足以下条件时适合新增业务组件：

- 页面中出现可命名的完整业务区块
- 这块 UI 有独立交互和状态
- 与已有组件相似但又不能直接复用
- 需要与模块内其他逻辑协同

示例：

- `MerchantListFilter`
- `OrderRefundPanel`
- `CampaignPublishStepper`

---

## 14. 常见反模式

避免以下做法：

- 页面文件超过很长但仍不拆
- 把所有内容提升到 shared 导致命名失真
- 一个组件同时处理请求、埋点、权限、复杂渲染和路由跳转
- 列表页复制粘贴后只改文案和字段
- 为了局部需求直接改基础组件
- 过度依赖 prop drilling，却不抽最近的组合组件

---

## 15. 推荐的决策顺序

当你准备新增一个功能块时，按以下顺序思考：

1. 它是页面、模块组件、共享业务组件还是基础组件
2. 它是否已有同类实现
3. 它的状态由谁持有
4. 它的请求由谁发起
5. 它需要暴露哪些 props / events
6. 它将来是否真实可能复用
7. 是否涉及危险区域

---

## 16. 注意事项

新增组件时，应注意：

- 优先寻找现有页面骨架和同类模块
- 优先延续已有命名与目录风格
- 不要默认把每个区块都抽成共享组件
- 不要把局部特例硬塞进公共组件
- 不要在 JSX / template 中堆大量业务逻辑
- 当组件边界不清时，先列出候选拆分方案，再选最贴近当前需求的一种
