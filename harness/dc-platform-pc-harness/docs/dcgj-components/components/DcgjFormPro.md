# DcgjFormPro 配置驱动的表单生成器

## 何时使用

当你需要通过 JSON Schema 配置快速生成表单，而不是手动编写每个 `Form.Item` 时，使用此组件。它支持 19+ 种内置控件类型、响应式布局、字段联动（显示/禁用/值计算）、远程选项加载、自定义组件插槽等能力。适合查询表单、编辑表单等需要大量表单字段的场景。如果你的表单只有 2-3 个字段，直接使用 antd 的 `Form` 即可。

## 基于

内部使用了 antd 的 `Form`、`Row`、`Col`、`Button`、`Space` 组件。

## 相比原生 antd 的差异

- ✅ 新增：通过 `formConfig` 数组配置驱动表单生成，无需手写 `Form.Item`
- ✅ 新增：内置 19+ 种控件类型（input/select/datePicker/cascader/upload 等）
- ✅ 新增：响应式布局（`isResponsive`），自动根据容器宽度调整列数
- ✅ 新增：字段联动——`visibleOn`（动态显隐）、`disabledOn`（动态禁用）、`valueChange`（值计算）
- ✅ 新增：`remoteConfig` 支持从 API 远程加载选项数据
- ✅ 新增：`preDesc`/`rearDesc` 在控件前后显示描述文本
- ✅ 新增：自定义组件注册（`registerComponent`）
- ✅ 新增：可替换的请求适配器（`setRequestAdapter`）
- 🔄 变更：提交按钮默认文本为"搜索"而非 antd 的"Submit"

## Props

| Prop | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `formConfig` | `FormConfigProps[]` | **是** | `[]` | 表单字段配置数组 |
| `model` | `Record<string, any>` | 否 | — | 表单数据对象（v-model） |
| `columns` | `Number` | 否 | — | 固定列数 |
| `isResponsive` | `Boolean` | 否 | `false` | 是否启用响应式布局 |
| `layout` | `string` | 否 | `'horizontal'` | 表单布局方向 |
| `labelCol` | `ColProps` | 否 | — | 标签列配置 |
| `wrapperCol` | `ColProps` | 否 | — | 控件列配置 |
| `defaultRowCount` | `Number` | 否 | `0` | 响应式模式下折叠前显示的行数 |
| `submitBtnText` | `String` | 否 | `'搜索'` | 提交按钮文本 |
| `resetBtnText` | `String` | 否 | `'重置'` | 重置按钮文本 |
| `resetBtnShow` | `Boolean` | 否 | `false` | 是否显示重置按钮 |
| `showActions` | `Boolean` | 否 | `true` | 是否显示操作按钮行 |
| `gutter` | `number \| [number, number]` | 否 | — | 栅格间距（响应式模式） |
| `disabled` | `Boolean` | 否 | `false` | 禁用所有表单项 |
| `size` | `'small' \| 'middle' \| 'large'` | 否 | — | 控件尺寸 |
| `rules` | `Object` | 否 | — | 表单验证规则 |

### FormConfigProps 类型

```ts
interface FormConfigProps {
  type: FormFiledType;        // 控件类型
  name: string;               // 字段名（对应 model 的 key）
  label?: string;             // 标签文本
  initialValue?: any;         // 默认值
  component?: Component;      // 自定义组件（type='custom' 时使用）
  fieldProps?: Record<string, any>;  // 传递给控件的 Props
  colProps?: ColProps;        // Col 配置（响应式模式）
  dependencies?: string[];    // 依赖的其他字段名
  visibleOn?: (deps: any[]) => boolean;      // 动态显隐
  disabledOn?: (deps: any[]) => boolean;     // 动态禁用
  valueChange?: (value: any, deps: any[]) => any; // 值计算
  rules?: any[];              // 字段验证规则
  help?: string;              // 帮助文本
  preDesc?: string;           // 控件前描述
  rearDesc?: string;          // 控件后描述
  remoteConfig?: RemoteConfig; // 远程选项配置
  optionsFetch?: (params: any) => Promise<any>; // 自定义选项获取函数
}

// 内置 type 值：
// 'input' | 'textArea' | 'inputNumber' | 'inputPassword' | 'mentions' |
// 'radio' | 'rate' | 'select' | 'checkbox' | 'slider' | 'switch' |
// 'timePicker' | 'timeRangePicker' | 'datePicker' | 'rangePicker' |
// 'transfer' | 'treeSelect' | 'upload' | 'cascader' | 'custom' | 'text'
```

### RemoteConfig 类型

```ts
interface RemoteConfig {
  apiEndpoint?: string;       // API 地址
  params?: Record<string, any>; // 请求参数
  headers?: Record<string, any>; // 请求头
  responseMapping?: string;   // 响应数据路径（默认 'data'）
  optionMapping?: { label: string; value: string }; // 选项字段映射
  method?: 'get' | 'post';
  body?: Record<string, any>;
}
```

## Events

| Event | Params | Description |
|-------|--------|-------------|
| `update:model` | `Record<string, any>` | v-model 更新，每次字段变更时触发 |
| `finish` | `values` | 表单验证通过后触发 |
| `finishFailed` | `{ values, errorFields }` | 表单验证失败后触发 |
| `reset` | 无 | 重置表单时触发 |

## Slots

| Slot | Scope Props | Description |
|------|-------------|-------------|
| `preDesc-{fieldName}` | 无 | 指定字段的控件前描述区域 |
| `rearDesc-{fieldName}` | 无 | 指定字段的控件后描述区域 |
| `label-{fieldName}` | 无 | 指定字段的标签覆盖 |
| `custom-{fieldName}` | `{ value }` | 指定字段的完全自定义渲染 |
| `extra-{fieldName}` | 无 | 指定字段 Form.Item 的 extra 区域 |
| `help-{fieldName}` | 无 | 指定字段 Form.Item 的 help 区域 |
| `extra-buttons` | 无 | 操作栏中额外按钮（重置按钮之后、折叠按钮之前） |
| `operator-buttons` | 无 | 完全替换默认操作按钮区域 |

## Expose

| Method/Property | Type | Description |
|-----------------|------|-------------|
| `validate` | `(nameList?: string[]) => Promise` | 触发表单验证 |
| `validateFields` | `(nameList?: string[]) => Promise` | 触发指定字段验证 |
| `resetFields` | `(nameList?: string[]) => void` | 重置表单字段 |
| `clearValidate` | `(nameList?: string[]) => void` | 清除验证状态 |
| `scrollToField` | `(nameList, options) => void` | 滚动到指定字段 |
| `setFieldsValue` | `(values: Record<string, any>) => void` | 设置字段值 |
| `getFormRef` | `() => FormInstance` | 获取底层 antd Form 实例 |
| `getFormModel` | `() => Record<string, any>` | 获取当前表单数据 |

## 使用示例

```vue
<!-- 示例 1：查询表单 -->
<template>
  <DcgjFormPro
    v-model:model="searchModel"
    :form-config="searchConfig"
    :reset-btn-show="true"
    @finish="handleSearch"
  />
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { DcgjFormPro } from 'dcgj-ui';
import type { FormConfigProps } from 'dcgj-ui';

const searchModel = ref({ name: '', status: '', dateRange: [] });

const searchConfig: FormConfigProps[] = [
  { type: 'input', name: 'name', label: '名称' },
  {
    type: 'select', name: 'status', label: '状态',
    fieldProps: {
      options: [
        { label: '启用', value: 1 },
        { label: '禁用', value: 0 },
      ],
    },
  },
  { type: 'rangePicker', name: 'dateRange', label: '日期范围' },
];

const handleSearch = (values: any) => {
  console.log('搜索:', values);
};
</script>
```

```vue
<!-- 示例 2：字段联动 + 响应式布局 -->
<template>
  <DcgjFormPro
    v-model:model="formModel"
    :form-config="formConfig"
    :is-responsive="true"
    :gutter="[16, 16]"
    layout="vertical"
    @finish="handleSubmit"
  />
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { DcgjFormPro } from 'dcgj-ui';
import type { FormConfigProps } from 'dcgj-ui';

const formModel = ref({ type: 1, customField: '' });

const formConfig: FormConfigProps[] = [
  {
    type: 'select', name: 'type', label: '类型',
    fieldProps: { options: [{ label: '类型A', value: 1 }, { label: '类型B', value: 2 }] },
  },
  {
    type: 'input', name: 'customField', label: '自定义字段',
    dependencies: ['type'],
    visibleOn: ([type]) => type === 2,  // 仅当 type=2 时显示
  },
  {
    type: 'select', name: 'region', label: '地区',
    remoteConfig: {
      apiEndpoint: '/api/regions',
      optionMapping: { label: 'name', value: 'code' },
    },
  },
];

const handleSubmit = (values: any) => {
  console.log('提交:', values);
};
</script>
```

## 注意事项

1. **字段插槽命名**：插槽名格式为 `{slotType}-{fieldName}`，如 `#custom-myField`、`#preDesc-name`。
2. **响应式模式**：设置 `isResponsive` 后，字段通过 `colProps` 控制栅格占比。`defaultRowCount` 控制折叠前显示的行数。
3. **远程选项**：`remoteConfig` 使用内置的 `fetch` 适配器，可通过 `setRequestAdapter` 替换为自定义请求函数。
4. **custom 类型**：当 `type` 为 `'custom'` 时，需要通过 `component` 字段传入 Vue 组件，或先用 `registerComponent` 注册。
5. **registerComponent**：可通过 `import { registerComponent } from 'dcgj-ui'` 注册自定义控件类型。
6. **setRequestAdapter**：可通过 `import { setRequestAdapter } from 'dcgj-ui'` 替换默认的请求适配器。
