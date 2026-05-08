# DcgjTable 带卡片布局和操作按钮区的表格

## 何时使用

当你需要一个带卡片外容器、顶部操作按钮区（左/右两侧）、自动分页的表格时，使用此组件。它在 antd Table 基础上增加了 `DcgjContentCard` 包裹、`TableOperateBtns` 按钮区（超过 3 个自动折叠为下拉菜单）、以及固定/浮动两种分页模式。如果你只需要一个裸表格，直接使用 antd 的 `Table` 即可。

## 基于

基于 `ant-design-vue` 的 `Table` 二次封装。

### 相比原生 antd 的差异

- ✅ 新增：`topLeft`/`topRight` 插槽，超过 3 个按钮自动折叠为"更多"下拉菜单
- ✅ 新增：`paginationType` 支持 `'fixed'`（固定底部）和 `'normal'`（浮动）两种分页模式
- ✅ 新增：内置 `DcgjContentCard` 卡片容器包裹
- ✅ 新增：`spaceSize` 控制操作按钮间距
- 🔄 变更：`tableData` 替代 antd 的 `dataSource` Prop 名
- 🔄 变更：`sticky` 默认为 `true`（antd 默认为 `false`）
- 🔄 变更：分页默认配置为 `pageSize: 10`、`showSizeChanger: true`、`showTotal` 显示"共 X 项数据"

## Props

| Prop | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `tableData` | `Array` | 否 | `[]` | 数据源（映射到 antd Table 的 `dataSource`） |
| `pagination` | `any` | 否 | `{}` | 分页配置。传 `false` 或空对象禁用分页 |
| `spaceSize` | `Number` | 否 | `10` | 操作按钮间距（px） |
| `paginationType` | `'normal' \| 'fixed'` | 否 | `'normal'` | 分页模式：`'normal'` 浮动，`'fixed'` 固定底部 |
| `sticky` | `Boolean \| Object` | 否 | `true` | 表头是否吸顶 |

> 继承说明：本组件透传了 antd `Table` 的所有 Props（如 `columns`、`rowKey`、`loading`、`scroll`、`rowSelection`、`size`、`bordered` 等），上表仅列出新增和覆盖的部分。完整 Props 请参考 antd 文档。

### 分页默认配置

```ts
{
  current: 1,
  pageSize: 10,
  total: 0,
  showSizeChanger: true,
  showQuickJumper: true,
  showTotal: (total) => `共 ${total} 项数据`,
}
```

## Events

继承 antd Table 的所有事件（如 `change`、`expand`、`resizeColumn`），无额外自定义事件。所有 `onXxx` 事件处理器会透传给内部 Table。

## Slots

| Slot | Scope Props | Description |
|------|-------------|-------------|
| `topLeft` | 无 | 表格左上角操作按钮区（超过 3 个自动折叠） |
| `topRight` | 无 | 表格右上角操作按钮区（超过 3 个自动折叠） |
| `default` | 无 | 透传给内部 Table 的所有插槽（如 `bodyCell`、`headerCell`、`summary`、`emptyText` 等） |

## Expose

| Method/Property | Type | Description |
|-----------------|------|-------------|
| `table` | `Ref<any>` | 内部 antd Table 实例的引用 |
| `paginationSelf` | `TablePaginationConfig` | 内部默认分页配置对象 |

## 使用示例

```vue
<!-- 示例 1：基础用法 -->
<template>
  <DcgjTable
    :columns="columns"
    :table-data="dataSource"
    :loading="loading"
    row-key="id"
    @change="handleTableChange"
  >
    <template #topLeft>
      <a-button type="primary" @click="handleAdd">新建</a-button>
    </template>
    <template #topRight>
      <a-button @click="handleExport">导出</a-button>
      <a-button @click="handleRefresh">刷新</a-button>
    </template>
    <template #bodyCell="{ column, record }">
      <template v-if="column.dataIndex === 'action'">
        <a @click="handleEdit(record)">编辑</a>
      </template>
    </template>
  </DcgjTable>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { DcgjTable } from '@/components';

const loading = ref(false);
const dataSource = ref([{ id: 1, name: '示例' }]);
const columns = [
  { title: '名称', dataIndex: 'name' },
  { title: '操作', dataIndex: 'action' },
];

const handleTableChange = (pagination: any, filters: any, sorter: any) => {
  console.log('分页:', pagination);
};
const handleAdd = () => {};
const handleExport = () => {};
const handleRefresh = () => {};
const handleEdit = (record: any) => {};
</script>
```

```vue
<!-- 示例 2：固定分页 + 行选择 -->
<template>
  <DcgjTable
    :columns="columns"
    :table-data="data"
    :row-selection="{ selectedRowKeys, onChange: onSelectChange }"
    pagination-type="fixed"
    :pagination="{ pageSize: 20, total: 100 }"
    row-key="id"
    :scroll="{ y: 500 }"
  >
    <template #topLeft>
      <a-button type="primary">批量操作</a-button>
    </template>
  </DcgjTable>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { DcgjTable } from '@/components';

const selectedRowKeys = ref<string[]>([]);
const data = ref([]);
const columns = [
  { title: 'ID', dataIndex: 'id' },
  { title: '名称', dataIndex: 'name' },
];

const onSelectChange = (keys: string[]) => {
  selectedRowKeys.value = keys;
};
</script>
```

## 注意事项

1. **tableData vs dataSource**：使用 `tableData` 传入数据（不要用 `dataSource`），组件内部会自动映射。
2. **按钮折叠**：`topLeft`/`topRight` 插槽中超过 3 个子元素时，第 4 个及以后的按钮会被放入"更多"下拉菜单。
3. **paginationType='fixed'**：此模式下 `DcgjContentCard` 会开启 `fullView`，表格撑满父容器，分页固定在底部。需确保父容器有明确高度。
4. **sticky 默认值**：与 antd 不同，`sticky` 默认为 `true`。设为 `false` 可关闭表头吸顶。
