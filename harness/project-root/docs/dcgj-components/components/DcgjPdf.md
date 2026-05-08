# DcgjPdfView PDF 文件卡片展示

## 何时使用

当你需要以卡片形式展示一个 PDF 文件的名称和下载链接时，使用此组件。它会自动从 URL 中提取文件名，并提供新窗口打开的下载能力。如果你需要在页面内嵌入 PDF 预览，此组件不适用。

## 基于

独立组件，非 antd 二次封装。

## 相比原生 antd 的差异

- ✅ 新增：自动从 URL 提取 PDF 文件名（带 `.pdf` 扩展名校验）
- ✅ 新增：内置 PDF 图标 + 文件名展示 + 新窗口下载链接
- ✅ 新增：文件名超长时自动省略 + Tooltip 显示完整名称
- 🔧 简化：只需传入一个 `url` 即可展示完整的 PDF 卡片

## Props

| Prop | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `url` | `String` | 否 | `''` | PDF 文件的 URL 地址 |

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
  <DcgjPdfView url="https://example.com/files/contract-2024.pdf" />
</template>

<script setup lang="ts">
import { DcgjPdfView } from 'dcgj-ui';
</script>
```

```vue
<!-- 示例 2：在描述列表中使用 -->
<template>
  <DcgjDesc title="附件信息" :data="descData" />
</template>

<script setup lang="ts">
import { DcgjDesc, DcgjPdfView } from 'dcgj-ui';
import { h } from 'vue';

const descData = [
  { label: '合同文件', value: h(DcgjPdfView, { url: 'https://example.com/contract.pdf' }), isComponent: true },
  { label: '备注', value: '无' },
];
</script>
```

## 注意事项

1. **文件名提取**：组件从 URL 路径中提取最后一段作为文件名，仅当以 `.pdf` 结尾时才显示。如果 URL 不含 `.pdf`，文件名可能显示为空。
2. **下载方式**：通过 `<a href={url} target="_blank">` 实现，受浏览器同源策略限制。
3. **静态展示**：此组件不支持 PDF 内容预览，仅展示文件卡片和下载链接。
