# DcgjBread 带吸顶和内容区的面包屑导航

## 何时使用

当你需要一个吸顶的面包屑导航栏，并且需要在面包屑右侧放置操作按钮、下方放置额外内容时，使用此组件。它会自动从 `vue-router` 的 `route.matched` 中提取面包屑数据，也支持手动传入 `list`。如果你只需要一个简单的面包屑，直接使用 antd 的 `Breadcrumb` 即可。

## 基于

独立组件，非 antd 二次封装。内部使用了 antd 的 `Affix`、`Breadcrumb`、`Divider` 和 `Flex` 组件。

## 相比原生 antd 的差异

- ✅ 新增：内置 `Affix` 吸顶能力，通过 `offsetTop` 和 `target` 控制
- ✅ 新增：自动从 `vue-router` 的 `route.matched` 生成面包屑（当 `list` 为空时）
- ✅ 新增：`right` 插槽用于在面包屑右侧放置操作按钮
- ✅ 新增：`content` 插槽用于在面包屑下方放置额外内容（带分隔线）
- 🔧 简化：`list` 数据结构简化为 `{ label, url }` 二元组

## Props

| Prop | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `list` | `BreadItemProps[]` | 否 | `[]` | 面包屑数据源，每项包含 `label` 和 `url`。为空时自动从路由生成 |
| `offsetTop` | `Number` | 否 | `0` | 吸顶偏移量（px） |
| `target` | `() => Window \| HTMLElement \| null` | 否 | `window` | 滚动容器，Affix 的 target |
| `bordered` | `Boolean` | 否 | `false` | 是否显示边框 |

> 类型说明：`BreadItemProps = { label?: string; url?: string }`

## Events

无自定义事件。

## Slots

| Slot | Scope Props | Description |
|------|-------------|-------------|
| `itemRender` | `{ item: route }` | 自定义每个面包屑项的渲染。`route` 包含 `label`、`url`、`path`、`breadcrumbName` |
| `right` | 无 | 面包屑右侧区域，通常放置操作按钮 |
| `content` | 无 | 面包屑下方内容区，与面包屑之间有分隔线 |

## Expose

无 Expose。

## 使用示例

```vue
<!-- 示例 1：基础用法（自动从路由生成面包屑） -->
<template>
  <DcgjBread>
    <template #right>
      <a-button type="primary">新建</a-button>
    </template>
  </DcgjBread>
</template>

<script setup lang="ts">
import { DcgjBread } from '@/components';
</script>
```

```vue
<!-- 示例 2：手动传入面包屑数据 + 吸顶 + 下方内容 -->
<template>
  <DcgjBread :list="breadList" :offset-top="64">
    <template #right>
      <a-space>
        <a-button>导出</a-button>
        <a-button type="primary">保存</a-button>
      </a-space>
    </template>
    <template #content>
      <a-alert message="当前页面数据为只读" type="info" />
    </template>
  </DcgjBread>
</template>

<script setup lang="ts">
import { DcgjBread } from '@/components';

const breadList = [
  { label: '首页', url: '/' },
  { label: '订单管理', url: '/orders' },
  { label: '订单详情' },
];
</script>
```

## 注意事项

1. **路由依赖**：当 `list` 为空时，组件会调用 `useRoute()` 从 `route.matched` 自动提取面包屑，依赖 `vue-router`。如果项目未使用 vue-router，必须传入 `list`。
2. **吸顶容器**：`target` 默认为 `window`，如果页面滚动容器不是 window（如某个 div），需要通过 `target` 指定。
3. **itemRender 默认行为**：有 `url` 的项渲染为 `<a>` 链接，无 `url` 的项渲染为纯文本。
