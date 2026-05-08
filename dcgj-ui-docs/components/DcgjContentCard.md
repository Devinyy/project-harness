# DcgjContentCard 带标题栏的内容卡片容器

## 何时使用

当你需要一个带可选标题栏、边框、全屏撑满能力的内容卡片容器时，使用此组件。典型场景是作为页面内容区域的外层包裹，标题栏左侧放标题、右侧放操作按钮。如果你只需要一个简单的卡片，直接使用 antd 的 `Card` 即可。

## 基于

独立组件，非 antd 二次封装。

## 相比原生 antd 的差异

- ✅ 新增：`fullView` 模式，卡片自动撑满父容器高度（`height: 100%` + `flex-grow`）
- ✅ 新增：`scrollAble` 控制内容区是否可滚动
- ✅ 新增：`showTitleBorder` 控制标题栏底部分割线
- ✅ 新增：`more` 插槽/Prop，专用于标题栏右侧的"更多"操作区域
- 🔧 简化：标题栏仅在有 `title` Prop 或 `title`/`more` 插槽时才渲染

## Props

| Prop | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `title` | `any` | 否 | — | 标题内容（也可通过 `title` 插槽传入） |
| `more` | `any` | 否 | — | 标题栏右侧内容（也可通过 `more` 插槽传入） |
| `showBorder` | `Boolean` | 否 | `false` | 是否显示卡片边框 |
| `showTitleBorder` | `Boolean` | 否 | `false` | 是否显示标题栏底部分割线 |
| `fullView` | `Boolean` | 否 | `false` | 卡片撑满父容器高度，内容区可滚动 |
| `scrollAble` | `Boolean` | 否 | `true` | 内容区是否允许纵向滚动（配合 `fullView` 使用） |

## Events

无自定义事件。

## Slots

| Slot | Scope Props | Description |
|------|-------------|-------------|
| `title` | 无 | 标题栏左侧内容，优先级高于 `title` Prop |
| `more` | 无 | 标题栏右侧内容，优先级高于 `more` Prop |
| `default` | 无 | 卡片主体内容 |

## Expose

无 Expose。

## 使用示例

```vue
<!-- 示例 1：基础用法 -->
<template>
  <DcgjContentCard title="订单列表">
    <template #more>
      <a-button type="link">查看更多</a-button>
    </template>
    <a-table :columns="columns" :data-source="data" />
  </DcgjContentCard>
</template>

<script setup lang="ts">
import { DcgjContentCard } from '@/components';
// columns, data 省略
</script>
```

```vue
<!-- 示例 2：全屏撑满模式（适合页面主内容区） -->
<template>
  <div style="height: 100vh; display: flex; flex-direction: column;">
    <DcgjContentCard title="数据看板" full-view show-title-border>
      <template #more>
        <a-space>
          <a-button>导出</a-button>
          <a-button type="primary">刷新</a-button>
        </a-space>
      </template>
      <DashboardContent />
    </DcgjContentCard>
  </div>
</template>

<script setup lang="ts">
import { DcgjContentCard } from '@/components';
import DashboardContent from './DashboardContent.vue';
</script>
```

## 注意事项

1. **标题栏条件渲染**：只有当 `title` Prop、`title` 插槽或 `more` 插槽任一存在时，标题栏才会渲染。
2. **fullView 使用条件**：父容器必须有明确的高度（如 `height: 100vh` 或 `flex` 布局），`fullView` 才能生效。
3. **scrollAble 默认为 true**：默认情况下内容区纵向可滚动。设为 `false` 可隐藏滚动条。
