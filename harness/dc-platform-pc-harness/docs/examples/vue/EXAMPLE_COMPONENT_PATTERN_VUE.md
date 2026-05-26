# EXAMPLE_COMPONENT_PATTERN_VUE.md

> 本示例只用于 Vue 3 + TypeScript + SFC 项目。
> 如果当前项目不是 Vue 技术栈，请不要引用本示例生成代码。

## 1. 示例目标

演示一个业务列表页的推荐拆分方式：

- 页面层只做路由级编排
- Feature 层承载业务筛选、表格、弹层
- Service 层隔离 API 协议
- Composable 层管理局部请求和交互状态

## 2. 推荐目录

```text
src/
├── pages/
│   └── merchant/
│       └── MerchantListPage.vue
├── features/
│   └── merchant/
│       ├── components/
│       │   ├── MerchantFilter.vue
│       │   ├── MerchantTable.vue
│       │   └── MerchantStatusTag.vue
│       ├── composables/
│       │   └── useMerchantList.ts
│       ├── constants.ts
│       └── types.ts
└── services/
    └── merchant/
        ├── merchantService.ts
        └── merchantAdapter.ts
```

## 3. 页面层示例

```vue
<script setup lang="ts">
import MerchantFilter from '@/features/merchant/components/MerchantFilter.vue'
import MerchantTable from '@/features/merchant/components/MerchantTable.vue'
import { useMerchantList } from '@/features/merchant/composables/useMerchantList'

const {
  filters,
  rows,
  loading,
  pagination,
  updateFilters,
  changePage,
  refresh,
} = useMerchantList()
</script>

<template>
  <section class="merchant-list-page">
    <MerchantFilter
      :model-value="filters"
      @update:model-value="updateFilters"
      @search="refresh"
    />
    <MerchantTable
      :rows="rows"
      :loading="loading"
      :pagination="pagination"
      @page-change="changePage"
    />
  </section>
</template>
```

## 4. Composable 示例

```ts
import { reactive, ref } from 'vue'
import { getMerchantList } from '@/services/merchant/merchantService'
import type { MerchantListFilters, MerchantListItem } from '../types'

export function useMerchantList() {
  const filters = reactive<MerchantListFilters>({
    keyword: '',
    status: undefined,
  })
  const rows = ref<MerchantListItem[]>([])
  const loading = ref(false)
  const pagination = reactive({ page: 1, pageSize: 20, total: 0 })

  async function refresh() {
    loading.value = true
    try {
      const result = await getMerchantList({
        ...filters,
        page: pagination.page,
        pageSize: pagination.pageSize,
      })
      rows.value = result.list
      pagination.total = result.total
    } finally {
      loading.value = false
    }
  }

  function updateFilters(next: MerchantListFilters) {
    Object.assign(filters, next)
    pagination.page = 1
  }

  function changePage(page: number, pageSize: number) {
    pagination.page = page
    pagination.pageSize = pageSize
    void refresh()
  }

  return {
    filters,
    rows,
    loading,
    pagination,
    updateFilters,
    changePage,
    refresh,
  }
}
```

## 5. 注意事项

- 不要把请求协议直接写进 `.vue` 页面
- 不要在 template 中写复杂字段转换
- 不要因为一个列表页需求新增全局 store
- Element Plus / Arco / 自研组件库的具体 API 应按当前项目真实组件替换
