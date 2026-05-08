# DcgjNumber 千分位格式化的数字展示

## 何时使用

当你需要展示一个带千分位分隔符的数字，并且可选地添加前缀（如货币符号）时，使用此组件。它是一个纯展示组件，不支持编辑。如果你需要一个可编辑的数字输入框，直接使用 antd 的 `InputNumber` 即可。

## 基于

独立组件，非 antd 二次封装。

## 相比原生 antd 的差异

- ✅ 新增：自动千分位分隔符格式化（如 `1234567` → `1,234,567`）
- ✅ 新增：`price` 快捷属性自动添加 `¥ ` 前缀
- ✅ 新增：`placeholder` 在数字为空或 NaN 时显示兜底文本
- 🔧 简化：纯展示组件，无交互逻辑

## Props

| Prop | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `number` | `string \| number` | **是** | — | 要展示的数字 |
| `decimal` | `Number \| String` | 否 | `2` | 小数位数 |
| `prefix` | `String` | 否 | `''` | 自定义前缀（如 `'元'`） |
| `price` | `Boolean` | 否 | `false` | 是否添加 `¥ ` 前缀（`prefix` 优先级更高） |
| `placeholder` | `String` | 否 | `''` | 数字为空或 NaN 时的占位文本 |

## Events

无自定义事件。

## Slots

无自定义 Slots。

## Expose

无 Expose。

## 使用示例

```vue
<!-- 示例 1：基础用法 -->
<template>
  <DcgjNumber :number="1234567.89" />
  <!-- 输出：1,234,567.89 -->
</template>

<script setup lang="ts">
import { DcgjNumber } from '@/components';
</script>
```

```vue
<!-- 示例 2：价格展示 + 自定义前缀 -->
<template>
  <a-space direction="vertical">
    <DcgjNumber :number="99800" price />
    <!-- 输出：¥ 99,800.00 -->

    <DcgjNumber :number="3.14159" :decimal="4" prefix="π≈" />
    <!-- 输出：π≈ 3.1416 -->

    <DcgjNumber :number="NaN" placeholder="暂无数据" />
    <!-- 输出：暂无数据 -->
  </a-space>
</template>

<script setup lang="ts">
import { DcgjNumber } from '@/components';
</script>
```

## 注意事项

1. **prefix 优先级**：`prefix` 和 `price` 同时设置时，`prefix` 优先。
2. **小数处理**：`decimal` 控制 `toFixed` 的位数，会进行四舍五入。
3. **空值处理**：当 `number` 为 `NaN`、`undefined` 或空字符串时，显示 `placeholder` 文本。
