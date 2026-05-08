# 06_UI_COMPONENT_GUIDE.md

---
owner: Frontend Team
last_verified: 2026-05-08
status: active
purpose: 统一前端页面中的组件选型、封装方式、布局规则与交互表现，确保 UI 决策保持一致。
primary_readers:
  - Frontend Developers
  - AI Agents
related:
  - 02_ARCHITECTURE.md
  - 04_CODING_STANDARDS.md
  - 05_COMPONENT_PATTERNS.md
  - 08_TASK_PLAYBOOKS.md
  - 09_TECH_SOLUTION_TEMPLATE.md
---

> 本文档重点是**选型规则、组合模式、约束边界、默认做法**。
> 组件的详细 Props、Events、Slots 请查阅 [dcgj-components/](./dcgj-components/) 目录下的各组件文档。

---

## 0. 当前项目采用情况

- 是否适用：`是`
- 当前项目 UI 组件库：`Dcgj UI（基于 Ant Design Vue 二次封装）`
- 当前项目样式方案：`CSS-in-JS（genComponentStyleHook）`
- 真实基础组件目录：`dcgj-ui`（统一导出入口）
- 真实业务组件目录：`dcgj-ui`（Dcgj 二开组件与 antd 组件统一从此导出）
- 禁止生成：
  - 禁止直接从 `ant-design-vue` 导入组件，必须从 `dcgj-ui` 导入
  - 禁止使用 antd 原始组件绕过 Dcgj 封装层（如直接用 antd `Table` 替代 `DcgjTable`）
  - 当存在 Dcgj 二开版本时，优先使用 Dcgj 版本（参见 [组件索引](./dcgj-components/COMPONENT_INDEX.md)）
- 详细组件 API 参考：[dcgj-components/COMPONENT_INDEX.md](./dcgj-components/COMPONENT_INDEX.md)

---

## 1. 使用原则

### 决策优先级

1. **优先复用现有业务组件**
2. 现有业务组件不满足时，**组合基础组件**
3. 基础组件无法满足时，**扩展或新增组件**（需说明无法复用的原因）

### 禁止事项

- 绕开现有组件体系，在页面里堆原子样式
- 因局部需求直接修改全局基础组件的默认行为
- 在多个页面复制同一套表单、表格、筛选栏实现
- 直接依赖 `ant-design-vue` 原始组件，跳过 `dcgj-ui` 封装层

### 默认原则

**一致性 > 局部好看 · 复用 > 快捷实现 · 组合 > 继承 · 配置 > 复制**

---

## 2. UI 组件分层

### 2.1 基础展示层（`dcgj-ui`）

对 Ant Design Vue 做二次封装，统一从 `dcgj-ui` 导入。核心组件：

| 组件 | 定位 |
|------|------|
| `DcgjTable` | 带卡片布局和操作按钮区的表格 |
| `DcgjFormPro` | 配置驱动的表单生成器 |
| `DcgjDrawer` | 带自动间距的底部操作栏抽屉 |
| `DcgjContentCard` | 带标题栏的内容卡片容器 |
| `DcgjBread` | 带吸顶和内容区的面包屑导航 |
| `DcgjUpload` | 带拖拽排序和七牛云上传的文件上传 |
| `DcgjDesc` | 自动识别内容类型的描述列表 |
| `DcgjImage` | 带下载能力的图片预览组 |
| `DcgjNumber` | 千分位格式化的数字展示 |
| `DcgjPdfView` | PDF 文件卡片展示 |
| `DcgjCascaderModal` | 弹窗式多层级联选择器 |
| `DcgjPayment` | 插件式支付流程引擎 |

详细 API 见 [dcgj-components/](./dcgj-components/)。

### 2.2 业务通用层

沉淀多模块重复出现的组合模式，如 `SearchFilterBar`（基于 `DcgjFormPro`）、`UserPicker`（基于 `DcgjCascaderModal`）。

### 2.3 模块内组件层 / 页面层

- 模块内组件（`features/*/components`）：服务单个模块，不污染全局
- 页面层（`pages/*`）：路由级容器，组合业务组件，不承载可复用 UI 实现

---

## 3. 组件选型

### 3.1 Dcgj 组件快速选择

| 场景 | 推荐组件 | 说明 |
|------|----------|------|
| 配置驱动表单 | `DcgjFormPro` | JSON Schema 配置生成，19+ 控件类型 |
| 带操作区的表格 | `DcgjTable` | 自带卡片容器、左右按钮区、分页 |
| 弹窗级联多选 | `DcgjCascaderModal` | 地区/部门等树形数据多选 |
| 文件上传 | `DcgjUpload` | 拖拽排序、七牛云、图片尺寸校验 |
| 底部操作栏抽屉 | `DcgjDrawer` | 默认 925px 宽、footer 自动间距 |
| 键值对描述展示 | `DcgjDesc` | 自动识别图片/PDF/组件类型 |
| 千分位数字展示 | `DcgjNumber` | 金额、价格等格式化展示 |
| 图片预览+下载 | `DcgjImage` | 缩略图+预览遮罩+下载按钮 |
| PDF 文件卡片 | `DcgjPdfView` | 文件名+下载链接 |
| 页面内容卡片 | `DcgjContentCard` | 标题栏+操作按钮+全屏撑满 |
| 面包屑导航 | `DcgjBread` | 吸顶+自动从路由生成 |
| 多步骤支付流程 | `DcgjPayment` | 插件式架构、金额管理、事件系统 |

### 3.2 选型规则

**弹层**：表单短/强打断 → Modal；表单长/需上下文 → `DcgjDrawer`。长表单禁止塞小型 Modal。

**数据展示**：筛选+查看+操作 → `DcgjTable`；浏览+理解 → List/Card。B 端列表页优先 Table。

**表单**：字段多 → `DcgjFormPro`；2-3 个字段 → antd `Form`。能枚举不手输，远程搜索必须处理 loading/empty/error。

**按钮**：每个区域通常 1 个主按钮；危险操作必须危险态；异步提交必须 loading 保护。

**反馈态**：所有异步区域至少考虑 loading、空态、错误态、提交成功反馈。

---

## 4. 页面级 UI 规则

**页面骨架**：PageHeader → FilterArea → ContentArea → SecondaryArea → FooterAction

**间距默认值**（以 design token 为准）：区块间距 24，元素垂直间距 16，表单项间距 12，筛选区与表格区间距 16~24。

**操作布局**：主操作靠近标题或底部固定区；危险操作远离主流程并增加确认；表格行内操作超 3 个折叠到"更多"。

---

## 5. 表单与表格标准

### 表单

- 每个字段必须有明确 label，必填项规则不依赖 placeholder
- 提交按钮需 disabled/loading 保护，编辑态与新建态明确区分
- 字段按业务语义分组（基础信息/配置项/权限/高级设置/风险操作）
- 只读态优先用描述性展示组件，不简单禁用控件

### 表格

- 列标题用业务术语，金额/时间/状态格式统一
- 操作列保持稳定，超 3 个折叠；状态优先用状态标签
- 筛选栏：常用默认展示，低频折叠，远程下拉必须防抖

---

## 6. 组件封装约定

**何时新建**：相同 UI + 业务语义在 2+ 页面重复出现时提炼。

**何时不要**：仅出现一次、仅字段顺序相似但语义不同、抽象后 props 爆炸。

**要求**：对外暴露少量语义清晰的 props；依赖接口优先解耦为外部传参或 hooks。

---

## 7. 反模式

- 页面间 copy 整段模板
- 为适配单页修改全局组件默认样式
- 状态标签在不同页面颜色/文案不一致
- 表单校验散落在多个 click handler 中
- 列表页缺 loading/empty/error 任一兜底
- 在 UI 组件里写大量接口请求与业务判断

---

## 8. 新增组件决策

新增组件前按以下顺序决策，违反任何一条需在技术方案中说明：

1. 是否已有同类组件可复用？
2. 属于基础层、业务通用层，还是模块内？
3. 是否真的会被复用？是否破坏一致性？
4. 是否需要 loading/empty/error/disabled/readonly/权限/埋点？
5. 是否有更轻的组合方式？

---

## 9. 无障碍、国际化与埋点

- **无障碍**：可点击元素有清晰文本或 aria-label；表单控件关联 label；禁止只靠颜色表达状态
- **国际化**：不在组件内硬编码业务文案；时间/金额/数字统一格式化
- **埋点**：关键操作（筛选/提交/导出/切换视图）需埋点，统一从埋点层管理

---

## 10. 项目定制区

### 10.1 基础组件映射

| 基础能力 | Dcgj 封装组件 | 基于 antd | 详细文档 |
|----------|--------------|-----------|----------|
| 表格 | `DcgjTable` | `Table` | [DcgjTable.md](./dcgj-components/components/DcgjTable.md) |
| 表单 | `DcgjFormPro` | `Form`/`Row`/`Col` | [DcgjFormPro.md](./dcgj-components/components/DcgjFormPro.md) |
| 抽屉 | `DcgjDrawer` | `Drawer` | [DcgjDrawer.md](./dcgj-components/components/DcgjDrawer.md) |
| 文件上传 | `DcgjUpload` | `Upload` | [DcgjUpload.md](./dcgj-components/components/DcgjUpload.md) |
| 图片预览 | `DcgjImage` | `Image` | [DcgjImage.md](./dcgj-components/components/DcgjImage.md) |
| 描述列表 | `DcgjDesc` | `Descriptions` | [DcgjDesc.md](./dcgj-components/components/DcgjDesc.md) |
| 数字展示 | `DcgjNumber` | 独立 | [DcgjNumber.md](./dcgj-components/components/DcgjNumber.md) |
| 面包屑 | `DcgjBread` | `Affix`/`Breadcrumb` | [DcgjBread.md](./dcgj-components/components/DcgjBread.md) |
| 内容卡片 | `DcgjContentCard` | 独立 | [DcgjContentCard.md](./dcgj-components/components/DcgjContentCard.md) |
| 级联选择 | `DcgjCascaderModal` | `Modal`/`Cascader`/`Checkbox` | [DcgjCascaderModal.md](./dcgj-components/components/DcgjCascaderModal.md) |
| PDF 展示 | `DcgjPdfView` | 独立 | [DcgjPdf.md](./dcgj-components/components/DcgjPdf.md) |
| 支付流程 | `DcgjPayment` | 独立 | [DcgjPayment.md](./dcgj-components/components/DcgjPayment.md) |

- RichText / Markdown 统一封装：wangEdit
- 所有组件统一从 `dcgj-ui` 导入，禁止从 `ant-design-vue` 直接导入

### 10.2 技术栈

- Vue 3 + TypeScript + Composition API
- CSS-in-JS（`genComponentStyleHook`）
- `@ant-design/icons-vue` 图标库
- `withInstall` 注册为 Vue 插件

### 10.3 需要重点避免改动的组件

- `DcgjTable` — 全局表格基类，改动影响所有列表页
- `DcgjFormPro` — 全局表单基类，改动影响所有表单页
- `DcgjDrawer` — 全局抽屉基类
- `DcgjContentCard` — 页面卡片容器基类

---

## 11. 真实性校验

- [ ] 组件库与当前 `package.json` 一致
- [ ] 基础组件目录在真实项目中存在
- [ ] 禁止组件库和禁止写法已写清
- [ ] UI 规则能在真实页面中找到样例
- [ ] 最后校验日期已更新
