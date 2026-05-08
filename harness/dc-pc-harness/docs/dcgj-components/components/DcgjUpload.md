# DcgjUpload 带拖拽排序和七牛云上传的文件上传组件

## 何时使用

当你需要一个功能完整的文件上传组件，支持图片/视频/PDF/Office 等多种文件类型、拖拽排序、图片尺寸校验、分片上传、文件预览和删除时，使用此组件。它内置了七牛云上传适配器，通过 v-model 绑定文件列表。如果你只需要一个简单的上传按钮且不需要这些增强能力，直接使用 antd 的 `Upload` 即可。

## 基于

基于 `ant-design-vue` 的 `Upload` 二次封装。

### 相比原生 antd 的差异

- ✅ 新增：拖拽排序（HTML5 Drag & Drop），通过 `draggable` 控制
- ✅ 新增：内置七牛云上传适配器，支持标准上传和分片上传（`isContinueUpload`）
- ✅ 新增：上传适配器注册表（`registry.ts`），支持自定义上传后端
- ✅ 新增：`features` 属性控制 UI 功能开关（`remove`/`preview`）
- ✅ 新增：`imageMaxWidth`/`imageMaxHeight` 图片尺寸校验
- ✅ 新增：`imageSizeLimit` 按文件扩展名设置不同的大小限制
- ✅ 新增：`useMd5FileName` 上传前对文件名进行 SHA-256 哈希
- ✅ 新增：`btnTheme` 支持 `'picture-card'` 和 `'button'` 两种按钮样式
- ✅ 新增：`fileChange` 事件携带操作类型（`upload`/`remove`/`reorder`）和详情
- 🔄 变更：通过 `value`（v-model）控制文件列表，而非 antd 的 `fileList`
- 🔄 变更：默认支持 30+ 种文件扩展名

## Props

| Prop | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `value` | `DCGJFile[]` | 否 | `[]` | 文件列表（v-model） |
| `accept` | `string[]` | 否 | 30+ 种扩展名 | 允许的文件扩展名列表 |
| `maxCount` | `number` | 否 | `10` | 最大文件数量 |
| `maxSize` | `number` | 否 | `10` | 单文件最大体积（MB） |
| `listType` | `'picture-card' \| 'picture'` | 否 | `'picture-card'` | 列表展示样式 |
| `btnTheme` | `'picture-card' \| 'button'` | 否 | `'picture-card'` | 上传按钮样式 |
| `them` | `string` | 否 | `'rect'` | 主题名 |
| `disabled` | `boolean` | 否 | `false` | 是否禁用 |
| `uploadText` | `string` | 否 | `'上传'` | 上传按钮文本 |
| `tipText` | `string` | 否 | `''` | 提示文本 |
| `isContinueUpload` | `boolean` | 否 | `false` | 是否启用分片上传 |
| `useMd5FileName` | `boolean` | 否 | `false` | 是否对文件名进行 SHA-256 哈希 |
| `imageMaxWidth` | `number` | 否 | `0` | 图片最大宽度（px，0=不限） |
| `imageMaxHeight` | `number` | 否 | `0` | 图片最大高度（px，0=不限） |
| `imageSizeLimit` | `Record<string, number>` | 否 | `{}` | 按扩展名设置大小限制（MB），如 `{ png: 2, jpg: 5 }` |
| `features` | `string[]` | 否 | `['remove', 'preview']` | 功能开关列表 |
| `draggable` | `boolean` | 否 | `true` | 是否允许拖拽排序 |

### DCGJFile 类型

```ts
interface DCGJFile extends UploadFile<any> {
  category?: 'image' | 'video' | 'audio' | 'pdf' | 'text' | 'file' | 'office' | 'excel';
  icon?: string;
  key?: string;
  retryFile?: File;
  progress?: number;
}
```

## Events

| Event | Params | Description |
|-------|--------|-------------|
| `update:value` | `DCGJFile[]` | v-model 更新 |
| `change` | `DCGJFile[]` | 文件列表变更（同 `update:value`） |
| `success` | `DCGJFile[]` | 单个文件上传完成或拖拽排序完成 |
| `fileChange` | `(DCGJFile[], action, detail)` | 文件变更详情。`action` 为 `'upload'`/`'remove'`/`'reorder'` |
| `processComplete` | `boolean` | 上传进度完成状态，所有文件 `percent===100` 时为 `true` |

## Slots

无自定义 Slots。

## Expose

无 Expose。

## 使用示例

```vue
<!-- 示例 1：基础用法 -->
<template>
  <DcgjUpload v-model:value="fileList" :max-count="5" @success="handleSuccess" />
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { DcgjUpload } from 'dcgj-ui';
import type { DCGJFile } from 'dcgj-ui';

const fileList = ref<DCGJFile[]>([]);

const handleSuccess = (files: DCGJFile[]) => {
  console.log('上传完成:', files);
};
</script>
```

```vue
<!-- 示例 2：图片上传 + 尺寸校验 + 按钮样式 -->
<template>
  <DcgjUpload
    v-model:value="images"
    :accept="['jpg', 'png', 'jpeg']"
    :max-count="3"
    :max-size="5"
    :image-max-width="1920"
    :image-max-height="1080"
    :image-size-limit="{ png: 2, jpg: 5 }"
    btn-theme="button"
    upload-text="选择图片"
    tip-text="支持 jpg/png，单张不超过 5MB"
    :features="['remove', 'preview']"
  />
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { DcgjUpload } from 'dcgj-ui';
import type { DCGJFile } from 'dcgj-ui';

const images = ref<DCGJFile[]>([]);
</script>
```

## 注意事项

1. **上传适配器**：组件默认使用七牛云上传适配器（通过 `initUploader` 初始化）。如需自定义上传后端，可使用 `registerUploader` 注册新的适配器。
2. **分片上传**：设置 `isContinueUpload` 为 `true` 后，使用 `qiniu-js` 进行分片上传，支持断点续传。
3. **拖拽排序**：`draggable` 默认为 `true`，通过 HTML5 Drag & Drop API 实现。排序后会触发 `fileChange` 事件，`action` 为 `'reorder'`，`detail` 包含 `{ fromIndex, toIndex }`。
4. **features 控制**：`features` 数组中包含 `'remove'` 时显示删除按钮，包含 `'preview'` 时显示预览按钮。
5. **图片尺寸校验**：`imageMaxWidth`/`imageMaxHeight` 仅在图片文件上传时生效，通过 Canvas 读取图片尺寸进行校验。
6. **registry.ts**：提供 `registerUploader(name, factory)` 和 `getUploader(name)` 用于注册和获取自定义上传器，目前组件内部未使用此机制，预留为未来扩展。
