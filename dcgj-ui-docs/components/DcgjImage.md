# DcgjImage 带下载能力的图片预览组

## 何时使用

当你需要展示一组图片缩略图，并且希望在预览时支持下载操作时，使用此组件。它基于 antd 的 `Image.PreviewGroup` 封装，在预览遮罩层上添加了"预览"和"下载"按钮。如果你不需要下载能力，直接使用 antd 的 `Image` 即可。

## 基于

基于 `ant-design-vue` 的 `Image` 和 `Image.PreviewGroup` 二次封装。

### 相比原生 antd 的差异

- ✅ 新增：预览遮罩层显示"预览"和"下载"按钮
- ✅ 新增：下载功能通过 Blob 方式实现，支持跨域图片
- ✅ 新增：`imageData` 数组驱动，支持每个图片独立的 fallback
- ✅ 新增：`bordered` 属性控制缩略图边框
- 🔧 简化：通过 `imageData` 数组统一管理图片列表

## Props

| Prop | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `imageData` | `ImageDataProps[]` | 否 | `[]` | 图片数据数组 |
| `imgWidth` | `Number` | 否 | `110` | 缩略图宽度（px） |
| `imgHeight` | `Number` | 否 | `110` | 缩略图高度（px） |
| `fallback` | `String` | 否 | 内置占位图 | 图片加载失败时的兜底图 |
| `isShowDownload` | `Boolean` | 否 | `true` | 预览时是否显示下载按钮 |
| `spaceSize` | `Number` | 否 | `16` | 图片间距（px） |
| `bordered` | `Boolean` | 否 | `true` | 是否显示边框 |

> 类型说明：`ImageDataProps = { url: string | null; fallback: string | null }`

> 继承说明：额外 attrs 会透传给底层 antd `Image` 组件。

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
  <DcgjImage :image-data="imageList" />
</template>

<script setup lang="ts">
import { DcgjImage } from '@/components';

const imageList = [
  { url: 'https://example.com/photo1.jpg', fallback: null },
  { url: 'https://example.com/photo2.jpg', fallback: null },
  { url: null, fallback: null },
];
</script>
```

```vue
<!-- 示例 2：自定义尺寸 + 隐藏下载 -->
<template>
  <DcgjImage
    :image-data="imageList"
    :img-width="200"
    :img-height="150"
    :is-show-download="false"
    :space-size="24"
    :bordered="false"
  />
</template>

<script setup lang="ts">
import { DcgjImage } from '@/components';

const imageList = [
  { url: 'https://example.com/1.jpg', fallback: 'https://example.com/placeholder.png' },
  { url: 'https://example.com/2.jpg', fallback: null },
];
</script>
```

## 注意事项

1. **边框尺寸**：当 `bordered` 为 `true` 时，实际缩略图尺寸会在 `imgWidth`/`imgHeight` 基础上各减 2px（用于边框）。
2. **下载实现**：下载通过 `fetch` 获取图片 Blob 再创建临时 `<a>` 元素触发，受浏览器 CORS 策略限制。
3. **空数据**：`imageData` 中 `url` 为 `null` 的项会显示 fallback 图片。
4. **继承 attrs**：非显式声明的属性会透传给底层 `Image` 组件，可使用 antd `Image` 的原生属性。
