# DcgjDesc 自动识别内容类型的描述列表

## 何时使用

当你需要展示一组键值对描述信息，且值可能是文本、图片、PDF 文件或自定义 Vue 组件时，使用此组件。它会根据值的类型自动选择渲染方式，省去手动判断的逻辑。如果你只需要一个标准的描述列表且值都是纯文本，直接使用 antd 的 `Descriptions` 即可。

## 基于

内部使用了 antd 的 `Descriptions`、`Image`、`Tooltip` 组件，以及自研的 `DcgjContentCard`、`DcgjImage`、`DcgjPdfView` 组件。

## 相比原生 antd 的差异

- ✅ 新增：自动识别值类型（图片数组、PDF 链接、Vue 组件、自定义渲染函数）
- ✅ 新增：`labelWidth` 属性统一控制所有标签宽度
- ✅ 新增：内置 `DcgjContentCard` 作为外层容器，支持 `title` 属性
- 🔄 变更：数据源使用 `data` 数组而非 `Descriptions.Item` 子组件
- 🔧 简化：通过 `data` 数组驱动，无需手动编写多个 `Descriptions.Item`

## Props

| Prop | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `data` | `FataProps[]` | **是** | — | 描述数据数组 |
| `title` | `any` | 否 | — | 标题（传递给 DcgjContentCard） |
| `column` | `Number` | 否 | `3` | 每行列数 |
| `bordered` | `Boolean` | 否 | `false` | 是否显示边框 |
| `labelWidth` | `Number` | 否 | `71` | 标签宽度（px） |

> 类型说明：`FataProps = { type?: string; label?: string; value: string | string[]; span?: number; render?: () => JSX.Element; [property: string]: any }`

### data 数组项的 value 类型判断规则

| 条件 | 渲染方式 |
|------|----------|
| `value` 为数组且首项以图片扩展名结尾（jpg/png/gif/svg 等） | 使用 `DcgjImage` 渲染图片组 |
| `value` 为以 `.pdf` 结尾的字符串，或 `type === 'pdf'` | 使用 `DcgjPdfView` 渲染 PDF 卡片 |
| `value` 为 Vue 组件（`isComponent` 为真） | 使用 `h(value, props)` 渲染组件 |
| `item.render` 存在 | 调用 `render()` 函数渲染 |
| 默认 | 渲染为带 Tooltip 的文本（超长省略） |

## Events

无自定义事件。

## Slots

| Slot | Scope Props | Description |
|------|-------------|-------------|
| `title` | 无 | 标题插槽，传递给内部的 `Descriptions` 组件 |

## Expose

无 Expose。

## 使用示例

```vue
<!-- 示例 1：基础用法 -->
<template>
  <DcgjDesc title="基本信息" :data="descData" />
</template>

<script setup lang="ts">
import { DcgjDesc } from 'dcgj-ui';
import type { FataProps } from 'dcgj-ui';

const descData: FataProps[] = [
  { label: '姓名', value: '张三' },
  { label: '年龄', value: '28' },
  { label: '证件照', value: ['https://example.com/photo.jpg'] },
  { label: '合同', value: 'https://example.com/contract.pdf' },
];
</script>
```

```vue
<!-- 示例 2：自定义渲染 + 组件嵌入 -->
<template>
  <DcgjDesc :data="descData" :column="2" :label-width="100" bordered />
</template>

<script setup lang="ts">
import { h } from 'vue';
import { DcgjDesc, DcgjNumber } from 'dcgj-ui';
import { Tag } from 'ant-design-vue';
import type { FataProps } from 'dcgj-ui';

const descData: FataProps[] = [
  { label: '订单编号', value: 'ORD20240101001' },
  { label: '订单金额', value: h(DcgjNumber, { number: 12345.67, price: true }), isComponent: true },
  { label: '状态', value: h(Tag, { color: 'green' }, () => '已完成'), isComponent: true },
  {
    label: '备注',
    value: '无',
    render: () => h('span', { style: { color: '#999' } }, '暂无备注'),
  },
];
</script>
```

## 注意事项

1. **FataProps 接口**：组件实际使用的 Props 接口为 `FataProps`（非 `DescDataProps`），`types.ts` 中的 `DescDataProps` 是旧版定义，当前未使用。
2. **图片识别**：仅当 `value` 为数组且首项以 `jpeg/jpg/png/gif/svg/jfif` 结尾时才识别为图片。
3. **组件渲染**：当 `isComponent` 为 `true` 时，`value` 应为一个 Vue 组件定义，`props` 字段会传递给该组件。
4. **v-html 警告**：默认文本渲染使用 `v-html`，请确保 `value` 内容可信。
