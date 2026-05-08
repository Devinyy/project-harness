# DCGJ UI 二开组件库文档

> 本文档面向 AI 编码助手，用于在开发者描述 UI 需求时快速匹配已有组件并生成调用代码。

## 组件索引

| 组件名 | 一句话定位 | 基于 antd | 文档链接 |
|--------|-----------|-----------|----------|
| `DcgjBread` | 带吸顶和内容区的面包屑导航 | 独立（使用 Affix/Breadcrumb） | [DcgjBread.md](./components/DcgjBread.md) |
| `DcgjCascaderModal` | 弹窗式多层级联选择器 | 独立（使用 Modal/Checkbox） | [DcgjCascaderModal.md](./components/DcgjCascaderModal.md) |
| `DcgjContentCard` | 带标题栏的内容卡片容器 | 独立 | [DcgjContentCard.md](./components/DcgjContentCard.md) |
| `DcgjDesc` | 自动识别内容类型的描述列表 | 独立（使用 Descriptions） | [DcgjDesc.md](./components/DcgjDesc.md) |
| `DcgjDrawer` | 带自动间距的底部操作栏抽屉 | Drawer | [DcgjDrawer.md](./components/DcgjDrawer.md) |
| `DcgjFormPro` | 配置驱动的表单生成器 | 独立（使用 Form/Row/Col） | [DcgjFormPro.md](./components/DcgjFormPro.md) |
| `DcgjImage` | 带下载能力的图片预览组 | Image / Image.PreviewGroup | [DcgjImage.md](./components/DcgjImage.md) |
| `DcgjNumber` | 千分位格式化的数字展示 | 独立 | [DcgjNumber.md](./components/DcgjNumber.md) |
| `DcgjPayment` | 插件式支付流程引擎 | 独立 | [DcgjPayment.md](./components/DcgjPayment.md) |
| `DcgjPdfView` | PDF 文件卡片展示 | 独立 | [DcgjPdf.md](./components/DcgjPdf.md) |
| `DcgjTable` | 带卡片布局和操作按钮区的表格 | Table | [DcgjTable.md](./components/DcgjTable.md) |
| `DcgjUpload` | 带拖拽排序和七牛云上传的文件上传 | Upload | [DcgjUpload.md](./components/DcgjUpload.md) |

## 快速选择指南

### 表单相关

| 需求 | 推荐组件 |
|------|----------|
| 通过 JSON 配置生成表单 | `DcgjFormPro` |
| 弹窗中多选树形数据（如地区选择） | `DcgjCascaderModal` |
| 文件上传（拖拽排序、图片校验、七牛云） | `DcgjUpload` |

### 数据展示

| 需求 | 推荐组件 |
|------|----------|
| 带操作按钮区和分页的表格 | `DcgjTable` |
| 展示文本/图片/PDF 混合的描述信息 | `DcgjDesc` |
| 展示带千分位的数字（价格、金额等） | `DcgjNumber` |
| 展示图片组并支持下载 | `DcgjImage` |
| 展示 PDF 文件卡片并支持下载 | `DcgjPdfView` |

### 布局容器

| 需求 | 推荐组件 |
|------|----------|
| 页面内容区卡片容器（标题 + 操作按钮） | `DcgjContentCard` |
| 面包屑导航（吸顶 + 右侧操作按钮） | `DcgjBread` |
| 带底部操作栏的抽屉 | `DcgjDrawer` |

### 业务流程

| 需求 | 推荐组件 |
|------|----------|
| 多步骤支付流程（插件化架构） | `DcgjPayment` |

## 导入方式

所有组件统一从 `@/components` 导入：

```ts
import {
  DcgjBread,
  DcgjCascaderModal,
  DcgjContentCard,
  DcgjDesc,
  DcgjDrawer,
  DcgjFormPro,
  DcgjImage,
  DcgjNumber,
  DcgjPayment,
  DcgjPdfView,
  DcgjTable,
  DcgjUpload,
} from '@/components';

// 类型导入
import type {
  FormConfigProps,
  DCGJFile,
  PaymentFlowConfig,
  PaymentStatus,
} from '@/components';
```

## 公共 API 导出

除组件外，以下工具函数/类型也从 `@/components` 导出：

| 名称 | 类型 | 来源组件 | 说明 |
|------|------|----------|------|
| `registerComponent` | 函数 | DcgjFormPro | 注册自定义表单控件类型 |
| `setRequestAdapter` | 函数 | DcgjFormPro | 替换默认的 fetch 请求适配器 |
| `registerUploader` | 函数 | DcgjUpload | 注册自定义上传适配器 |
| `getUploader` | 函数 | DcgjUpload | 获取已注册的上传适配器 |
| `FormConfigProps` | 类型 | DcgjFormPro | 表单字段配置接口 |
| `DCGJFile` | 类型 | DcgjUpload | 文件数据接口 |
| `ImageDataProps` | 类型 | DcgjImage | 图片数据接口 |
| `FataProps` | 类型 | DcgjDesc | 描述列表数据项接口 |
| `PaymentFlowConfig` | 类型 | DcgjPayment | 支付流程配置接口 |
| `PaymentStatus` | 枚举 | DcgjPayment | 支付状态枚举 |
| `BreadItemProps` | 类型 | DcgjBread | 面包屑数据项接口 |
| `FieldNames` | 类型 | DcgjCascaderModal | 级联字段名映射接口 |
| `LevelNode` | 类型 | DcgjCascaderModal | 树节点接口 |
| `DcgjContentCardProps` | 类型 | DcgjContentCard | 卡片容器 Props 接口 |

## 可用的 Ant Design Vue 组件

以下 antd 组件均可从 `@/components` 直接导入，使用标准 antd API（参考 [Ant Design Vue 文档](https://www.antdv.com/)）。**无需从 `ant-design-vue` 单独导入。**

> **重要**：当项目中存在对应的 Dcgj 二开组件时（如 `DcgjTable` vs `Table`、`DcgjDrawer` vs `Drawer`），优先使用 Dcgj 版本。详见上方「快速选择指南」。

### 通用

| 组件 | 说明 |
|------|------|
| `Button`, `ButtonGroup` | 按钮 |
| `Icon` | 图标（通常配合 `@ant-design/icons-vue` 使用） |
| `Typography`, `TypographyText`, `TypographyTitle`, `TypographyParagraph`, `TypographyLink` | 排版 |
| `Flex` | 弹性布局 |
| `Space`, `Compact` | 间距 |
| `Divider` | 分割线 |
| `ConfigProvider` | 全局配置 |

### 布局

| 组件 | 说明 |
|------|------|
| `Row`, `Col` | 栅格布局 |
| `Layout`, `LayoutHeader`, `LayoutSider`, `LayoutFooter`, `LayoutContent` | 页面布局 |
| `Grid` | 栅格系统 |

### 导航

| 组件 | 说明 |
|------|------|
| `Affix` | 固钉 |
| `Breadcrumb`, `BreadcrumbItem`, `BreadcrumbSeparator` | 面包屑 |
| `Menu`, `MenuItem`, `MenuItemGroup`, `SubMenu`, `MenuDivider` | 导航菜单 |
| `Pagination` | 分页 |
| `Steps`, `Step` | 步骤条 |
| `Tabs`, `TabPane` | 标签页 |
| `Anchor`, `AnchorLink` | 锚点链接 |

### 数据录入

| 组件 | 说明 |
|------|------|
| `AutoComplete`, `AutoCompleteOption`, `AutoCompleteOptGroup` | 自动完成 |
| `Cascader` | 级联选择 |
| `Checkbox`, `CheckboxGroup` | 复选框 |
| `DatePicker`, `MonthPicker`, `WeekPicker`, `RangePicker`, `QuarterPicker` | 日期选择 |
| `Form`, `FormItem`, `FormItemRest` | 表单 |
| `Input`, `InputGroup`, `InputPassword`, `InputSearch`, `Textarea` | 输入框 |
| `InputNumber` | 数字输入框 |
| `Mentions`, `MentionsOption` | 提及 |
| `Radio`, `RadioGroup`, `RadioButton` | 单选框 |
| `Rate` | 评分 |
| `Select`, `SelectOption`, `SelectOptGroup` | 选择器 |
| `Slider` | 滑动输入条 |
| `Switch` | 开关 |
| `TimePicker`, `TimeRangePicker` | 时间选择 |
| `Transfer` | 穿梭框 |
| `TreeSelect`, `TreeSelectNode` | 树选择 |
| `Upload`, `UploadDragger` | 上传 |

### 数据展示

| 组件 | 说明 |
|------|------|
| `Avatar`, `AvatarGroup` | 头像 |
| `Badge`, `BadgeRibbon` | 徽标数 |
| `Calendar` | 日历 |
| `Card`, `CardGrid`, `CardMeta` | 卡片 |
| `Carousel` | 走马灯 |
| `Collapse`, `CollapsePanel` | 折叠面板 |
| `Comment` | 评论 |
| `Descriptions`, `DescriptionsItem` | 描述列表 |
| `Empty` | 空状态 |
| `Image`, `ImagePreviewGroup` | 图片 |
| `List`, `ListItem`, `ListItemMeta` | 列表 |
| `Popover` | 气泡卡片 |
| `Statistic`, `StatisticCountdown` | 统计数值 |
| `Table`, `TableColumn`, `TableColumnGroup`, `TableSummary`, `TableSummaryRow`, `TableSummaryCell` | 表格 |
| `Tabs`, `TabPane` | 标签页 |
| `Tag`, `CheckableTag` | 标签 |
| `Timeline`, `TimelineItem` | 时间轴 |
| `Tooltip` | 文字提示 |
| `Tree`, `TreeNode`, `DirectoryTree` | 树形控件 |
| `Segmented` | 分段控制器 |
| `QRCode` | 二维码 |

### 反馈

| 组件 | 说明 |
|------|------|
| `Alert` | 警告提示 |
| `Drawer` | 抽屉 |
| `Modal` | 对话框 |
| `message` | 全局提示（函数式 API，`message.info('...')` ） |
| `notification` | 通知提醒（函数式 API） |
| `Popconfirm` | 气泡确认框 |
| `Progress` | 进度条 |
| `Result` | 结果 |
| `Skeleton`, `SkeletonButton`, `SkeletonAvatar`, `SkeletonInput`, `SkeletonImage`, `SkeletonTitle` | 骨架屏 |
| `Spin` | 加载中 |

### 其他

| 组件 | 说明 |
|------|------|
| `App` | 应用容器（配合 `message`/`notification` 使用） |
| `BackTop` | 回到顶部 |
| `FloatButton`, `FloatButtonGroup` | 悬浮按钮 |
| `LocaleProvider` | 国际化（已废弃，使用 `ConfigProvider`） |
| `PageHeader` | 页头 |
| `Tour` | 漫游式引导 |
| `Watermark` | 水印 |

## 技术栈

- Vue 3 + TypeScript + Composition API
- 基于 Ant Design Vue 的二次封装组件库
- CSS-in-JS 样式方案（`genComponentStyleHook`）
- `withInstall` 注册为 Vue 插件
