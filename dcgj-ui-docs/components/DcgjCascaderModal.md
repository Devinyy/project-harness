# DcgjCascaderModal 弹窗式多层级联选择器

## 何时使用

当你需要在一个弹窗中通过 Checkbox 树进行多层级联选择（如地区选择），且选中结果需要以扁平数组形式存储时，使用此组件。适用于数据层级较深（2-3 层）、需要批量勾选的场景。如果你只需要一个普通的级联下拉框，直接使用 antd 的 `Cascader` 即可。

## 基于

独立组件，非 antd 二次封装。内部使用了 antd 的 `Modal`、`Cascader`、`Checkbox`、`Tooltip`、`Space`、`Flex` 组件。

## 相比原生 antd 的差异

- ✅ 新增：弹窗式交互，通过 Checkbox 树进行多选，支持全选/半选状态
- ✅ 新增：`labelType` 属性支持三种触发器样式（`select`/`text`/`slot`）
- ✅ 新增：`selectionDepth` 控制选择深度（1=仅一级，2=一二级，3=全部）
- ✅ 新增：`showCheckedStrategy` 控制返回值策略（`SHOW_PARENT`/`SHOW_CHILD`）
- ✅ 新增：叶子节点勾选数统计，父节点显示已选数量
- 🔄 变更：`value` 为扁平 `string[]`（外层），内部自动转换为 `string[][]` 路径数组

## Props

| Prop | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `options` | `LevelNode[]` | **是** | — | 树形数据源 |
| `value` | `string[] \| number[]` | 否 | `[]` | 选中值的扁平数组（v-model） |
| `labelType` | `'select' \| 'text' \| 'slot'` | 否 | `'select'` | 触发器渲染模式 |
| `title` | `string` | 否 | `'请选择地区'` | 弹窗标题 |
| `placeholder` | `string` | 否 | `'请选择'` | 级联选择器占位文本 |
| `inputSize` | `'small' \| 'middle' \| 'large'` | 否 | `'default'` | 选择器尺寸 |
| `selectionDepth` | `1 \| 2 \| 3` | 否 | `3` | 选择深度：1=仅一级，2=一二级，3=全部层级 |
| `fieldNames` | `FieldNames` | 否 | `{}` | 字段名映射（`label`/`value`/`code`/`children` 等） |
| `showCheckedStrategy` | `'SHOW_PARENT' \| 'SHOW_CHILD'` | 否 | `'SHOW_CHILD'` | 选中项展示策略 |
| `maxTagCount` | `number` | 否 | — | 多选时最多显示的标签数 |
| `showCancelBtn` | `boolean` | 否 | `true` | 弹窗中是否显示取消按钮 |

> 类型说明：`LevelNode = { code?: string; name?: string; label?: string; value?: string; children?: LevelNode[]; parentCode?: string; disabled?: boolean; isLeaf?: boolean }`
> 类型说明：`FieldNames = { name?: string; label?: string; value?: string; code?: string; key?: string; parentCode?: string; children?: string }`

## Events

| Event | Params | Description |
|-------|--------|-------------|
| `update:value` | `string[][]` | v-model 更新，选中值路径数组 |
| `change` | `string[][]` | 确认选择时触发，返回选中值路径数组 |
| `cancel` | 无 | 取消弹窗时触发 |

## Slots

| Slot | Scope Props | Description |
|------|-------------|-------------|
| `label` | 无 | 自定义触发器内容。仅在 `labelType="slot"` 时生效 |

## Expose

无 Expose。

## 使用示例

```vue
<!-- 示例 1：基础用法 -->
<template>
  <DcgjCascaderModal
    v-model:value="selectedKeys"
    :options="areaOptions"
    @change="handleChange"
  />
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { DcgjCascaderModal } from '@/components';

const selectedKeys = ref<string[]>(['110000', '110101']);

const areaOptions = [
  {
    code: '110000', name: '北京市',
    children: [
      { code: '110101', name: '东城区' },
      { code: '110102', name: '西城区' },
    ],
  },
];

const handleChange = (value: string[][]) => {
  console.log('选中路径:', value);
};
</script>
```

```vue
<!-- 示例 2：文本模式 + 自定义字段映射 -->
<template>
  <DcgjCascaderModal
    v-model:value="selectedKeys"
    :options="treeData"
    label-type="text"
    :field-names="{ label: 'title', value: 'id', children: 'items' }"
    :selection-depth="2"
    title="选择部门"
  />
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { DcgjCascaderModal } from '@/components';

const selectedKeys = ref<string[]>([]);
const treeData = [
  {
    id: '1', title: '技术部',
    items: [
      { id: '1-1', title: '前端组' },
      { id: '1-2', title: '后端组' },
    ],
  },
];
</script>
```

## 注意事项

1. **值格式**：外层 `value` 是扁平的 code 数组（如 `['110000', '110101']`），内部转换为 `string[][]` 路径数组。`change` 事件返回的是路径数组格式。
2. **字段映射**：默认使用 `code`/`name`/`children` 作为字段名，可通过 `fieldNames` 自定义。
3. **弹窗挂载**：弹窗通过 `Teleport` 挂载到 `document.body`，不受父组件样式影响。
4. **selectionDepth**：设为 `1` 时只能勾选一级节点，设为 `2` 时可勾选一级和二级，设为 `3` 时可勾选所有层级。
