# DcgjDrawer 带自动间距的底部操作栏抽屉

## 何时使用

当你需要一个抽屉组件，且底部操作栏（footer）的多个按钮组之间需要自动添加间距时，使用此组件。它默认宽度为 925px、底部右对齐，footer 中的子元素会自动添加 8px 的左边距。如果你不需要 footer 自动间距，直接使用 antd 的 `Drawer` 即可。

## 基于

基于 `ant-design-vue` 的 `Drawer` 二次封装。

### 相比原生 antd 的差异

- ✅ 新增：footer 插槽子元素自动添加 `marginLeft: 8px` 间距（首个子元素除外）
- 🔄 变更：默认宽度从 antd 的 378/736 改为 `925px`
- 🔄 变更：footer 默认右对齐（`textAlign: 'right'`）
- 🔄 变更：`onClose` 事件名替代 antd 的 `close` 事件

## Props

| Prop | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `title` | `String` | 否 | `''` | 抽屉标题 |
| `placement` | `'top' \| 'right' \| 'bottom' \| 'left'` | 否 | `'right'` | 抽屉弹出方向 |
| `open` | `Boolean` | 否 | `false` | 是否可见（v-model） |
| `width` | `Number` | 否 | `925` | 抽屉宽度（px） |

> 继承说明：本组件透传了 antd `Drawer` 的所有 Props（如 `closable`、`maskClosable`、`destroyOnClose`、`bodyStyle`、`headerStyle` 等），上表仅列出新增和覆盖的部分。完整 Props 请参考 antd 文档。

## Events

| Event | Params | Description |
|-------|--------|-------------|
| `onClose` | 无 | 关闭抽屉时触发 |

> 继承 antd Drawer 的所有事件（如 `update:open`、`afterOpenChange`），`onClose` 为额外自定义事件。

## Slots

| Slot | Scope Props | Description |
|------|-------------|-------------|
| `default` | 无 | 抽屉主体内容 |
| `footer` | 无 | 底部操作栏，子元素自动添加间距 |
| `extra` | 无 | 标题栏右侧额外内容（如关闭按钮旁的图标） |

## Expose

无 Expose。

## 使用示例

```vue
<!-- 示例 1：基础用法 -->
<template>
  <DcgjDrawer v-model:open="visible" title="订单详情" @on-close="handleClose">
    <p>抽屉内容</p>
    <template #footer>
      <a-button @click="visible = false">取消</a-button>
      <a-button type="primary" @click="handleSubmit">确认</a-button>
    </template>
  </DcgjDrawer>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { DcgjDrawer } from 'dcgj-ui';

const visible = ref(false);
const handleClose = () => { visible.value = false; };
const handleSubmit = () => { /* ... */ };
</script>
```

```vue
<!-- 示例 2：多按钮组 footer -->
<template>
  <DcgjDrawer v-model:open="visible" title="编辑" :width="600">
    <DcgjFormPro :form-config="formConfig" :model="formModel" />
    <template #footer>
      <a-button @click="visible = false">取消</a-button>
      <a-button type="primary" @click="handleSave">保存</a-button>
      <a-button @click="handleSaveAndClose">保存并关闭</a-button>
    </template>
    <template #extra>
      <a-tooltip title="帮助">
        <QuestionCircleOutlined />
      </a-tooltip>
    </template>
  </DcgjDrawer>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { DcgjDrawer } from 'dcgj-ui';
import { QuestionCircleOutlined } from '@ant-design/icons-vue';

const visible = ref(false);
// formConfig, formModel, handleSave, handleSaveAndClose 省略
</script>
```

## 注意事项

1. **footer 间距**：footer 插槽中的子元素（非首个）会自动添加 `marginLeft: 8px`，无需手动添加间距。
2. **footerStyle 覆盖**：默认 `footerStyle` 为 `{ textAlign: 'right' }`，可通过 attrs 传入自定义 `footerStyle` 覆盖。
3. **事件命名**：关闭事件名为 `onClose`（而非 antd 的 `close`），使用时注意绑定 `@on-close`。
