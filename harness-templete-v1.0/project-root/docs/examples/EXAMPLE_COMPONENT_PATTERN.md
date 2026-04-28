# EXAMPLE_COMPONENT_PATTERN.md

> 说明：这是 `05_COMPONENT_PATTERNS.md` 和 `06_UI_COMPONENT_GUIDE.md` 的组件实现示例。
> 场景完全虚构，请替换为你项目的真实业务。
> 本示例展示一个典型的 Feature 组件从目录结构、类型定义、hook 封装、组件实现到样式组织的完整写法。

---
owner: Frontend Team
last_verified: 2026-04-21
status: example
purpose: 演示 Feature 层组件的标准目录结构、Props 设计、Hook 封装、状态管理与样式组织方式，帮助开发者生成风格一致的组件代码。
related:
  - ../05_COMPONENT_PATTERNS.md
  - ../06_UI_COMPONENT_GUIDE.md
  - ../04_CODING_STANDARDS.md
  - ../07_API_CONTRACTS.md
---

## 1. 场景说明

以"商家列表页的筛选区 + 表格 + 行操作"为例，展示一个 Feature 模块的完整组织方式。

涉及组件：

- `MerchantFilter` — 筛选栏
- `MerchantTable` — 表格 + 行操作
- `MerchantStatusTag` — 状态标签
- `useMerchantColumns` — 表格列定义 hook
- `useMerchantListQuery` — 列表请求 hook

涉及层级：

- Page 层：`pages/merchant/ListPage`
- Feature 层：`features/merchant/*`
- Service 层：`services/merchant/*`
- Shared 层：复用 `AppTable`、`SearchFilterBar`、`StatusTag`、`ConfirmActionModal`

---

## 2. 目录结构

```text
src/
├── pages/
│   └── merchant/
│       └── ListPage.tsx                # 页面入口（轻量编排）
├── features/
│   └── merchant/
│       ├── components/
│       │   ├── MerchantFilter/
│       │   │   ├── index.ts
│       │   │   ├── MerchantFilter.tsx
│       │   │   └── types.ts
│       │   ├── MerchantTable/
│       │   │   ├── index.ts
│       │   │   ├── MerchantTable.tsx
│       │   │   └── types.ts
│       │   └── MerchantStatusTag.tsx    # 简单组件，单文件即可
│       ├── hooks/
│       │   ├── useMerchantColumns.ts
│       │   └── useMerchantListQuery.ts
│       ├── constants.ts
│       └── types.ts                     # 模块级共享类型
├── services/
│   └── merchant/
│       ├── merchant.service.ts
│       ├── merchant.adapter.ts
│       └── merchant.types.ts
└── shared/
    └── ui/
        ├── AppTable/
        ├── StatusTag/
        └── SearchFilterBar/
```

### 2.1 为什么这样组织

- **Page 层只编排**：ListPage 只负责组合 Filter + Table，不写具体表格列、筛选逻辑
- **Feature 层承载业务**：筛选、列定义、行操作、状态标签都属于商家模块，放在 features/merchant
- **Hook 与组件分离**：列定义和请求逻辑独立为 hook，方便复用和测试
- **简单组件不过度拆分**：MerchantStatusTag 只有一个文件，不需要文件夹
- **Service 层隔离请求**：请求、适配、类型放在 services/merchant，不散落在页面中

---

## 3. 类型定义

### 3.1 Service 层类型（services/merchant/merchant.types.ts）

```ts
/**
 * 后端返回的原始 DTO，字段保持与接口文档一致
 */
export interface MerchantListItemDTO {
  merchant_id: string
  merchant_name: string
  merchant_type: string
  status: 'ENABLED' | 'DISABLED'
  store_count: number
  created_at: string | null
  contact_name: string | null
}

export interface MerchantListRequestDTO {
  page: number
  pageSize: number
  keyword?: string
  status?: 'ENABLED' | 'DISABLED'
  merchantType?: string
}

export interface MerchantListResponseDTO {
  list: MerchantListItemDTO[]
  total: number
}
```

### 3.2 Feature 层类型（features/merchant/types.ts）

```ts
/**
 * 前端展示模型，字段已转换为前端命名风格
 * 与 DTO 的映射关系见 merchant.adapter.ts
 */
export interface MerchantListItem {
  merchantId: string
  merchantName: string
  merchantType: string
  status: MerchantStatus
  storeCount: number
  createdAt: string
  contactName: string
}

export type MerchantStatus = 'enabled' | 'disabled'

/**
 * 筛选条件
 */
export interface MerchantFilterValues {
  keyword: string
  status: MerchantStatus | ''
  merchantType: string
}
```

### 3.3 为什么 DTO 和 ViewModel 分离

- DTO 对齐后端契约，字段名保持 snake_case，方便与接口文档对照
- ViewModel 对齐前端习惯，字段名 camelCase，枚举值小写，空值已兜底
- 两者之间的转换集中在 adapter，不散落在页面各处

---

## 4. Service 与 Adapter

### 4.1 Adapter（services/merchant/merchant.adapter.ts）

```ts
import type { MerchantListItemDTO } from './merchant.types'
import type { MerchantListItem } from '@/features/merchant/types'

/**
 * 将后端 DTO 转换为前端展示模型
 * - 字段重命名
 * - 枚举值归一化
 * - 空值兜底
 */
export function adaptMerchantListItem(dto: MerchantListItemDTO): MerchantListItem {
  return {
    merchantId: dto.merchant_id,
    merchantName: dto.merchant_name,
    merchantType: dto.merchant_type,
    status: dto.status === 'ENABLED' ? 'enabled' : 'disabled',
    storeCount: dto.store_count ?? 0,
    createdAt: dto.created_at ?? '-',
    contactName: dto.contact_name ?? '-',
  }
}
```

### 4.2 Service（services/merchant/merchant.service.ts）

```ts
import { httpClient } from '@/shared/http'
import type { MerchantListRequestDTO, MerchantListResponseDTO } from './merchant.types'
import type { MerchantListItem } from '@/features/merchant/types'
import { adaptMerchantListItem } from './merchant.adapter'

/**
 * 查询商家列表
 * 调用方：useMerchantListQuery
 */
export async function getMerchantList(
  params: MerchantListRequestDTO,
): Promise<{ list: MerchantListItem[]; total: number }> {
  const res = await httpClient.get<MerchantListResponseDTO>('/api/merchants', {
    params,
  })

  return {
    list: res.list.map(adaptMerchantListItem),
    total: res.total,
  }
}

/**
 * 切换商家状态
 * 调用方：MerchantTable 行操作
 */
export async function toggleMerchantStatus(
  merchantId: string,
  targetStatus: 'ENABLED' | 'DISABLED',
): Promise<void> {
  await httpClient.post(`/api/merchants/${merchantId}/status`, {
    status: targetStatus,
  })
}
```

---

## 5. Hooks

### 5.1 列表请求 Hook（features/merchant/hooks/useMerchantListQuery.ts）

```ts
import { useState, useCallback } from 'react'
import { getMerchantList } from '@/services/merchant/merchant.service'
import type { MerchantListItem, MerchantFilterValues } from '../types'

interface UseMerchantListQueryOptions {
  defaultPageSize?: number
}

interface UseMerchantListQueryResult {
  data: MerchantListItem[]
  total: number
  loading: boolean
  error: Error | null
  page: number
  pageSize: number
  setPage: (page: number) => void
  setPageSize: (size: number) => void
  refresh: () => void
  search: (filters: MerchantFilterValues) => void
}

/**
 * 商家列表请求 hook
 *
 * 职责：
 * - 管理分页、筛选参数
 * - 发起请求并持有加载/错误状态
 * - 暴露 refresh 和 search 方法供页面调用
 *
 * 不负责：
 * - 筛选表单的 UI 状态（由 MerchantFilter 管理）
 * - 表格列定义（由 useMerchantColumns 管理）
 */
export function useMerchantListQuery(
  options: UseMerchantListQueryOptions = {},
): UseMerchantListQueryResult {
  const { defaultPageSize = 20 } = options

  const [data, setData] = useState<MerchantListItem[]>([])
  const [total, setTotal] = useState(0)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<Error | null>(null)
  const [page, setPage] = useState(1)
  const [pageSize, setPageSize] = useState(defaultPageSize)
  const [filters, setFilters] = useState<MerchantFilterValues>({
    keyword: '',
    status: '',
    merchantType: '',
  })

  const fetchData = useCallback(async () => {
    setLoading(true)
    setError(null)

    try {
      const result = await getMerchantList({
        page,
        pageSize,
        keyword: filters.keyword || undefined,
        status: filters.status
          ? (filters.status === 'enabled' ? 'ENABLED' : 'DISABLED')
          : undefined,
        merchantType: filters.merchantType || undefined,
      })

      setData(result.list)
      setTotal(result.total)
    } catch (err) {
      setError(err instanceof Error ? err : new Error('请求失败'))
    } finally {
      setLoading(false)
    }
  }, [page, pageSize, filters])

  const search = useCallback((newFilters: MerchantFilterValues) => {
    setFilters(newFilters)
    setPage(1) // 筛选变化时重置到第一页
  }, [])

  const refresh = useCallback(() => {
    fetchData()
  }, [fetchData])

  return { data, total, loading, error, page, pageSize, setPage, setPageSize, refresh, search }
}
```

> **注意**：以上为原生 useState 写法，便于理解。
> 实际项目中如使用 TanStack Query / SWR / Pinia 等，请替换为对应的请求管理方式，
> 但 hook 的职责边界（参数管理、请求、刷新）保持不变。

### 5.2 列定义 Hook（features/merchant/hooks/useMerchantColumns.ts）

```ts
import type { ColumnsType } from 'antd/es/table'
import type { MerchantListItem } from '../types'
import { MerchantStatusTag } from '../components/MerchantStatusTag'
import { formatDateTime } from '@/shared/utils/date'

interface UseMerchantColumnsOptions {
  onToggleStatus: (item: MerchantListItem) => void
  onViewDetail: (item: MerchantListItem) => void
  /** 当前用户是否有状态操作权限 */
  canToggleStatus: boolean
}

/**
 * 商家表格列定义
 *
 * 为什么抽成 hook：
 * - 列定义依赖权限判断和操作回调，不适合写成纯常量
 * - 多个页面可能复用同一套列（列表页、选择弹窗等）
 * - 避免在页面组件中堆大段 columns 配置
 */
export function useMerchantColumns(
  options: UseMerchantColumnsOptions,
): ColumnsType<MerchantListItem> {
  const { onToggleStatus, onViewDetail, canToggleStatus } = options

  return [
    {
      title: '商家名称',
      dataIndex: 'merchantName',
      width: 200,
      ellipsis: true,
    },
    {
      title: '商家类型',
      dataIndex: 'merchantType',
      width: 120,
    },
    {
      title: '门店数',
      dataIndex: 'storeCount',
      width: 80,
      align: 'right',
    },
    {
      title: '状态',
      dataIndex: 'status',
      width: 100,
      render: (status: MerchantListItem['status']) => (
        <MerchantStatusTag status={status} />
      ),
    },
    {
      title: '联系人',
      dataIndex: 'contactName',
      width: 120,
    },
    {
      title: '创建时间',
      dataIndex: 'createdAt',
      width: 180,
      render: (val: string) => formatDateTime(val),
    },
    {
      title: '操作',
      width: 150,
      fixed: 'right',
      render: (_: unknown, record: MerchantListItem) => (
        <span>
          <a onClick={() => onViewDetail(record)}>查看</a>
          {canToggleStatus && (
            <>
              <span style={{ margin: '0 8px', color: '#ddd' }}>|</span>
              <a onClick={() => onToggleStatus(record)}>
                {record.status === 'enabled' ? '停用' : '启用'}
              </a>
            </>
          )}
        </span>
      ),
    },
  ]
}
```

---

## 6. 组件实现

### 6.1 状态标签 — 单文件组件（features/merchant/components/MerchantStatusTag.tsx）

```tsx
import { StatusTag } from '@/shared/ui/StatusTag'
import type { MerchantStatus } from '../types'

interface MerchantStatusTagProps {
  status: MerchantStatus
}

/**
 * 商家状态标签
 *
 * 复用 shared/ui/StatusTag，只做商家状态 → 颜色/文案的映射
 * 映射规则与 03_BUSINESS_DOMAIN.md 和 07_API_CONTRACTS.md 保持一致
 */
const STATUS_MAP: Record<MerchantStatus, { label: string; color: string }> = {
  enabled: { label: '启用中', color: 'success' },
  disabled: { label: '已停用', color: 'default' },
}

export function MerchantStatusTag({ status }: MerchantStatusTagProps) {
  const config = STATUS_MAP[status] ?? STATUS_MAP.disabled
  return <StatusTag color={config.color}>{config.label}</StatusTag>
}
```

**要点**：

- 状态映射集中在一个 `STATUS_MAP` 常量中，不散落在各处
- 复用 shared 层的 `StatusTag` 基础组件，只添加业务语义
- 对未知状态有兜底（`?? STATUS_MAP.disabled`）

### 6.2 筛选栏 — 文件夹组件

**types.ts**

```ts
import type { MerchantFilterValues } from '../../types'

export interface MerchantFilterProps {
  /** 当前筛选值 */
  value: MerchantFilterValues
  /** 筛选条件变化回调 */
  onChange: (values: MerchantFilterValues) => void
  /** 点击重置 */
  onReset: () => void
  /** 是否正在加载 */
  loading?: boolean
}
```

**MerchantFilter.tsx**

```tsx
import { Input, Select } from 'antd'
import { SearchFilterBar } from '@/shared/ui/SearchFilterBar'
import { MERCHANT_TYPE_OPTIONS } from '../constants'
import { MERCHANT_STATUS_OPTIONS } from '../constants'
import type { MerchantFilterProps } from './types'

/**
 * 商家筛选栏
 *
 * 职责：
 * - 管理筛选表单 UI
 * - 变化时通过 onChange 通知父级
 *
 * 不负责：
 * - 发起请求（由 useMerchantListQuery 负责）
 * - 管理分页（由页面层负责）
 */
export function MerchantFilter({ value, onChange, onReset, loading }: MerchantFilterProps) {
  const handleFieldChange = (field: string, fieldValue: string) => {
    onChange({ ...value, [field]: fieldValue })
  }

  return (
    <SearchFilterBar onReset={onReset} loading={loading}>
      <Input
        placeholder="搜索商家名称"
        value={value.keyword}
        onChange={(e) => handleFieldChange('keyword', e.target.value)}
        allowClear
        style={{ width: 200 }}
      />
      <Select
        placeholder="商家状态"
        value={value.status || undefined}
        onChange={(val) => handleFieldChange('status', val ?? '')}
        options={MERCHANT_STATUS_OPTIONS}
        allowClear
        style={{ width: 140 }}
      />
      <Select
        placeholder="商家类型"
        value={value.merchantType || undefined}
        onChange={(val) => handleFieldChange('merchantType', val ?? '')}
        options={MERCHANT_TYPE_OPTIONS}
        allowClear
        style={{ width: 140 }}
      />
    </SearchFilterBar>
  )
}
```

**index.ts**

```ts
export { MerchantFilter } from './MerchantFilter'
export type { MerchantFilterProps } from './types'
```

### 6.3 表格 — 文件夹组件

**MerchantTable.tsx**

```tsx
import { AppTable } from '@/shared/ui/AppTable'
import type { MerchantListItem } from '../../types'
import type { ColumnsType } from 'antd/es/table'

interface MerchantTableProps {
  columns: ColumnsType<MerchantListItem>
  data: MerchantListItem[]
  loading: boolean
  total: number
  page: number
  pageSize: number
  onPageChange: (page: number) => void
  onPageSizeChange: (size: number) => void
}

/**
 * 商家表格
 *
 * 职责：
 * - 展示商家列表数据
 * - 处理分页
 *
 * 不负责：
 * - 列定义（由 useMerchantColumns 提供）
 * - 数据请求（由 useMerchantListQuery 提供）
 * - 行操作逻辑（由页面层组合）
 */
export function MerchantTable({
  columns,
  data,
  loading,
  total,
  page,
  pageSize,
  onPageChange,
  onPageSizeChange,
}: MerchantTableProps) {
  return (
    <AppTable
      rowKey="merchantId"
      columns={columns}
      dataSource={data}
      loading={loading}
      pagination={{
        current: page,
        pageSize,
        total,
        onChange: onPageChange,
        onShowSizeChange: (_, size) => onPageSizeChange(size),
      }}
      scroll={{ x: 1000 }}
    />
  )
}
```

---

## 7. Page 层编排

```tsx
// pages/merchant/ListPage.tsx

import { useState, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import { message, Modal } from 'antd'
import { PageContainer } from '@/shared/ui/PageContainer'
import { MerchantFilter } from '@/features/merchant/components/MerchantFilter'
import { MerchantTable } from '@/features/merchant/components/MerchantTable'
import { useMerchantListQuery } from '@/features/merchant/hooks/useMerchantListQuery'
import { useMerchantColumns } from '@/features/merchant/hooks/useMerchantColumns'
import { toggleMerchantStatus } from '@/services/merchant/merchant.service'
import { usePermission } from '@/shared/hooks/usePermission'
import type { MerchantFilterValues, MerchantListItem } from '@/features/merchant/types'

const DEFAULT_FILTERS: MerchantFilterValues = {
  keyword: '',
  status: '',
  merchantType: '',
}

/**
 * 商家列表页
 *
 * 职责：
 * - 组合 Filter + Table
 * - 编排筛选 → 请求 → 展示 → 操作 → 刷新 的主流程
 * - 接入权限判断
 *
 * 不负责：
 * - 表格列定义细节（useMerchantColumns）
 * - 请求与分页管理细节（useMerchantListQuery）
 * - 筛选栏 UI 细节（MerchantFilter）
 */
export default function MerchantListPage() {
  const navigate = useNavigate()
  const canToggleStatus = usePermission('merchant:status:toggle')

  const [filters, setFilters] = useState<MerchantFilterValues>(DEFAULT_FILTERS)

  const {
    data, total, loading, page, pageSize,
    setPage, setPageSize, refresh, search,
  } = useMerchantListQuery()

  // ── 操作回调 ──

  const handleSearch = useCallback((newFilters: MerchantFilterValues) => {
    setFilters(newFilters)
    search(newFilters)
  }, [search])

  const handleReset = useCallback(() => {
    setFilters(DEFAULT_FILTERS)
    search(DEFAULT_FILTERS)
  }, [search])

  const handleViewDetail = useCallback((item: MerchantListItem) => {
    navigate(`/merchant/${item.merchantId}`)
  }, [navigate])

  const handleToggleStatus = useCallback((item: MerchantListItem) => {
    const targetStatus = item.status === 'enabled' ? 'DISABLED' : 'ENABLED'
    const actionText = item.status === 'enabled' ? '停用' : '启用'

    Modal.confirm({
      title: `确认${actionText}`,
      content: `确定要${actionText}商家「${item.merchantName}」吗？`,
      onOk: async () => {
        await toggleMerchantStatus(item.merchantId, targetStatus)
        message.success(`${actionText}成功`)
        refresh()
      },
    })
  }, [refresh])

  // ── 列定义 ──

  const columns = useMerchantColumns({
    onViewDetail: handleViewDetail,
    onToggleStatus: handleToggleStatus,
    canToggleStatus,
  })

  // ── 渲染 ──

  return (
    <PageContainer title="商家管理">
      <MerchantFilter
        value={filters}
        onChange={handleSearch}
        onReset={handleReset}
        loading={loading}
      />

      <MerchantTable
        columns={columns}
        data={data}
        loading={loading}
        total={total}
        page={page}
        pageSize={pageSize}
        onPageChange={setPage}
        onPageSizeChange={setPageSize}
      />
    </PageContainer>
  )
}
```

---

## 8. 常量定义（features/merchant/constants.ts）

```ts
import type { MerchantStatus } from './types'

/**
 * 商家状态选项（筛选栏用）
 */
export const MERCHANT_STATUS_OPTIONS = [
  { label: '启用中', value: 'enabled' as MerchantStatus },
  { label: '已停用', value: 'disabled' as MerchantStatus },
]

/**
 * 商家类型选项
 * 来源：后端字典，若将来改为动态获取，替换为 hook
 */
export const MERCHANT_TYPE_OPTIONS = [
  { label: '直营', value: 'DIRECT' },
  { label: '加盟', value: 'FRANCHISE' },
  { label: '连锁', value: 'CHAIN' },
]
```

---

## 9. 关键设计决策说明

### 9.1 为什么筛选状态放在 Page 层，不放在 Filter 内部

- Filter 是受控组件，value 和 onChange 由外部传入
- 这样 Page 层可以统一管理"筛选 → 请求 → 分页重置"的时序
- 如果将来筛选条件需要同步到 URL，Page 层改造即可，不需要动 Filter

### 9.2 为什么列定义用 hook 而不是常量

- 列中的"操作列"依赖权限判断和回调函数，不是纯静态数据
- hook 可以接收 options 参数，让同一套列定义在不同场景（列表页 vs 选择弹窗）下复用
- 如果列定义不依赖任何动态值，用常量文件也可以

### 9.3 为什么 MerchantStatusTag 没有抽到 shared 层

- 当前只在商家模块内使用
- 它依赖 `MerchantStatus` 类型，带有明确的模块语义
- 如果将来多个模块都需要类似的状态标签，再提升到 shared 层并泛化命名

### 9.4 为什么 adapter 在 service 层而不是 hook 层

- adapter 的职责是"DTO → ViewModel 的转换"，与请求紧密相关
- 放在 service 层可以保证 hook 拿到的就是干净的前端模型
- 避免多个 hook 或页面重复写同一套转换逻辑

---

## 10. 检查清单

本示例覆盖了以下要求：

- [x] 类型：DTO 与 ViewModel 分离，所有 Props 有明确类型
- [x] 命名：文件 PascalCase / camelCase 一致，hook 以 use 开头
- [x] 分层：Page 编排 → Feature 业务组件 → Shared 基础组件 → Service 请求
- [x] Hook 职责清晰：useMerchantListQuery 管请求，useMerchantColumns 管列
- [x] Props 设计：受控模式，语义清晰，无过多布尔开关
- [x] 状态映射集中：STATUS_MAP 统一管理文案和颜色
- [x] 空值兜底：adapter 中处理 null → 默认值
- [x] 错误处理：hook 中 catch error 并暴露 error 状态
- [x] 权限：操作按钮受 canToggleStatus 控制
- [x] 二次确认：状态切换使用 Modal.confirm
- [x] 刷新策略：操作成功后调用 refresh
- [x] 组件注释：每个组件和 hook 都有"职责"和"不负责"说明

---

## 11. Vue 项目适配说明

如果项目使用 Vue + Composition API，核心结构不变，主要差异：

- 组件文件：`.vue` 单文件组件
- hook → composable：`useMerchantListQuery.ts` 写法类似，使用 `ref` / `computed` / `watch`
- Props 定义：`defineProps<MerchantFilterProps>()`
- Events 定义：`defineEmits<{ change: [values: MerchantFilterValues] }>()`
- 表格列：根据 UI 库（Element Plus / Arco）调整列定义格式

目录结构、分层原则、命名规范保持一致。

---

## 12. 反模式对照

以下是本示例有意避免的反模式：

| 反模式 | 本示例做法 |
|--------|-----------|
| 所有逻辑堆在 Page 里 | Page 只编排，列定义、请求、筛选各自分离 |
| 列定义里塞业务计算 | 列定义只做展示映射，操作回调由外部传入 |
| 多个页面重复写状态标签映射 | 集中到 MerchantStatusTag + STATUS_MAP |
| 页面直接调接口 | 通过 service 函数 + adapter 统一处理 |
| 筛选组件内部管理请求 | 受控模式，筛选只通知变化，请求由 hook 管理 |
| 一上来就把组件抽到 shared | MerchantStatusTag 留在 feature 层，等真实复用再提升 |
