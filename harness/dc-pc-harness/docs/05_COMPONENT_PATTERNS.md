# 05_COMPONENT_PATTERNS.md

---
owner: Frontend Team
last_verified: 2026-05-08
status: active
purpose: 沉淀组件分层、目录组织、页面骨架、表单/列表/弹层等常见实现模式，帮助开发者快速复用成熟方案。
primary_readers:
  - Frontend Developers
  - AI Agents
related:
  - 02_ARCHITECTURE.md
  - 04_CODING_STANDARDS.md
  - 06_UI_COMPONENT_GUIDE.md
  - 08_TASK_PLAYBOOKS.md
  - 11_DANGEROUS_AREAS.md
---

> 本文件强调"怎么组织组件与逻辑"。
> `06_UI_COMPONENT_GUIDE.md` 负责"选什么 UI"，本文件负责"怎么拆、怎么放、怎么复用"。

---

## 0. 当前项目采用情况

- **适用**：是
- **组件语法**：Vue 3 SFC，`<script setup lang="ts">`
- **无 `features/` 目录**：本项目不使用 `features/` 分层，采用扁平三层结构（见第 3 节）

### 真实组件目录（以 app-product / app-merchant 为代表）

| 目录 | 职责 |
|------|------|
| `src/views/{context}/` | 路由入口页面，只做组件组合与弹层局部状态 |
| `src/components/common/` | 跨领域通用组件，无具体业务上下文 |
| `src/components/{domain}/` | 域内业务组件（app-product，按领域平铺） |
| `src/components/{domain}/{context}/` | 域内业务组件（app-merchant，按 list/detail/form/shared 细分） |
| `src/composables/` | 纯逻辑 composable，不含模板 |

### 不要使用的写法

- 不要创建 `features/` 目录
- 不要创建 `shared/` 目录（通用组件统一放 `components/common/`）
- 不要在 `views/` 里直接调用 API 函数（走 composable）
- 不要在 `components/` 里直接调用 `router.push` 或全局 store（向上 emit 或由 composable 处理）

---

## 1. 组件模式目标

1. 让相似页面具备一致的结构，降低读新页面的认知成本
2. 让新增需求先复用已有模式，延迟抽象
3. 让页面层保持轻量——组合组件，不承载可复用 UI 实现
4. 让 composable 承担所有数据逻辑，使页面模板和组件各自专注

---

## 2. 组件分层

本项目采用三层结构，不使用 feature/shared 分层。

### 2.1 Page 组件（`src/views/`）

职责：
- 路由入口，文件名小写（`list.vue`、`detail.vue`、`form.vue`）
- 调用 composable，解构其返回值后传给子组件
- 管理弹层的 open/loading/record 等纯展示状态
- 不写请求逻辑，不写字段转换

典型结构（参考 `views/product/list.vue`）：

```vue
<template>
  <section class="product-list">
    <ProductSearchForm :draft="draftQuery" @search="search" @reset="reset" />
    <ProductTable :products="products" :loading="loading" @offline="openOfflineModal" />
    <ProductOfflineConfirmModal :open="offlineConfirmOpen" @confirm="confirmOfflineProduct" />
  </section>
</template>

<script setup lang="ts">
  import { ref } from 'vue';
  import ProductSearchForm from '@/components/product/ProductSearchForm.vue';
  import ProductTable from '@/components/product/ProductTable.vue';
  import ProductOfflineConfirmModal from '@/components/product/ProductOfflineConfirmModal.vue';
  import { useProductListQuery } from '@/composables/useProductListQuery';

  const { products, loading, draftQuery, search, reset, offlineProduct } = useProductListQuery();

  // 弹层状态：只有 open/loading/record，不含业务逻辑
  const offlineConfirmOpen = ref(false);
  const offlineConfirmLoading = ref(false);

  const openOfflineModal = (record: ProductRecord) => { ... };
  const confirmOfflineProduct = async () => { ... };
</script>
```

### 2.2 域内业务组件（`src/components/{domain}/` 或 `src/components/{domain}/{context}/`）

职责：
- 服务单个业务领域的可复用组件片段
- SearchForm、Table、Modal、DetailPanel、SectionCard、StatusSelect 等
- 通过 props 接收数据，通过 emit 发出用户操作
- 不直接调用 API，不持有全局 store

app-product 采用 `components/{domain}/` 平铺命名（`product/`、`price-rule/`）。

app-merchant 采用按页面分组（`components/merchant/detail/`、`components/merchant/form/`、`components/merchant/list/`、`components/merchant/shared/`）。

### 2.3 通用基础组件（`src/components/common/`）

职责：
- 跨多个领域复用，无具体业务上下文
- 实例：`StatusTag.vue`、`PriceText.vue`、`CopyableText.vue`、`CommonRemotePagedSelect.vue`

不应包含：
- 特定领域的业务判断逻辑
- 对具体 API 的直接调用

---

## 3. 目录组织

### 3.1 真实目录结构（app-product）

```text
src/
├── views/
│   ├── product/
│   │   ├── list.vue
│   │   └── detail.vue
│   └── price-rule/
│       ├── list.vue
│       ├── detail.vue
│       └── form.vue
├── components/
│   ├── common/
│   │   ├── StatusTag.vue
│   │   ├── PriceText.vue
│   │   └── CommonRemotePagedSelect.vue
│   ├── product/
│   │   ├── ProductSearchForm.vue
│   │   ├── ProductTable.vue
│   │   └── ...
│   └── price-rule/
│       ├── PriceRuleSearchForm.vue
│       └── ...
├── composables/
│   ├── useProductListQuery.ts
│   ├── useProductDetail.ts
│   ├── usePriceRuleListQuery.ts
│   ├── usePriceRuleForm.ts
│   └── usePriceRuleSelection.ts
├── api/
├── types/
└── router/
```

### 3.2 真实目录结构（app-merchant）

```text
src/
├── views/
│   └── merchant/
│       ├── list.vue
│       ├── detail.vue
│       ├── form.vue
│       └── audit.vue
├── components/
│   ├── common/
│   │   ├── CopyableText.vue
│   │   ├── StickyFooter.vue
│   │   └── SectionTitle.vue
│   └── merchant/
│       ├── list/
│       │   ├── MerchantSearchForm.vue
│       │   ├── MerchantTable.vue
│       │   └── MerchantStatusConfirmDialog.vue
│       ├── detail/
│       │   ├── MerchantDetailOverviewSection.vue
│       │   └── ...
│       ├── form/
│       │   ├── BasicInfoSection.vue
│       │   └── ...
│       └── shared/
│           ├── StatusSwitchWithConfirm.vue
│           └── ProfitRateEditor.vue
├── composables/
│   ├── useMerchantQuery.ts
│   ├── useMerchantDetail.ts
│   └── useMerchantForm.ts
```

### 3.3 单文件 vs 多文件

本项目所有组件均为单文件（`.vue`），没有文件夹组件。当一个组件需要子组件时，子组件单独建文件而不是嵌套在同一目录。

---

## 4. 何时拆组件

满足以下任一条件时建议拆：

- 这一块 UI 有独立名称且职责清晰（`ProductSearchForm`、`PriceRuleDetailPanel`）
- 模板超过约 80 行且有可命名的子区块
- 该区块在页面中重复两次以上
- 该区块有独立的交互状态（展开/折叠、选中等）

不要拆的情况：

- 只有 3-5 个字段且无重复，强拆反而增加跳转成本
- 为了"看起来整洁"而拆出没有命名价值的组件

---

## 5. Composable 模式

### 5.1 职责划分

Composable 负责：
- 列表请求（loadings、records、total、query）
- 查询条件与 URL 同步
- 详情请求和字段适配
- 表单状态、校验、提交
- 多组件共享的业务操作（offlineProduct、batchOffline）

Composable 不负责：
- 弹层的 open/close 状态（留在 views 里）
- 路由跳转后的回调（由调用方决定）
- 全局 toast 以外的 UI 反馈

### 5.2 命名规则

| App | 模式 | 例子 |
|-----|------|------|
| app-product | `use{Domain}{Purpose}` | `useProductListQuery`、`usePriceRuleForm` |
| app-merchant | `use{Domain}{Purpose}` | `useMerchantQuery`、`useMerchantDetail`、`useMerchantForm` |

新增 composable 时参照同 app 已有命名。

### 5.3 标准结构

```typescript
export function use{Domain}ListQuery() {
  const route = useRoute();
  const router = useRouter();

  const records = ref<DomainRecord[]>([]);
  const total = ref(0);
  const loading = ref(false);
  const query = reactive<DomainQuery>(readQueryFromRoute());

  // 监听路由变化，自动同步查询并触发请求
  watch(() => route.query, () => {
    Object.assign(query, readQueryFromRoute());
    void fetchList();
  }, { immediate: true });

  async function fetchList() {
    loading.value = true;
    try {
      const result = await queryDomainList(buildDomainPageReq(query));
      records.value = result.records || [];
      total.value = Number(result.total || 0);
    } catch {
      records.value = [];
      total.value = 0;
    } finally {
      loading.value = false;
    }
  }

  function changePage(pageNum: number) {
    void router.replace({ query: { ...route.query, pageNum: String(pageNum) } });
  }

  // 内部函数不暴露；只暴露 views 需要的内容
  return { records, total, loading, query, changePage };
}
```

关键要点：
- 所有异步函数用 `try/catch/finally`，catch 时将数据重置为空
- 未 await 的异步调用加 `void`（如 `void fetchList()`）
- 内部辅助函数不出现在 return 里

---

## 6. Props / Events 设计

### 6.1 Props

```typescript
// defineProps 使用泛型语法，不用 defineProps({})
const props = defineProps<{
  products: ProductRecord[];
  loading: boolean;
  query: ProductQuery;
  total: number;
}>();
```

- props 只传组件真正需要的字段，不把整个 composable 返回值塞进去
- 枚举型 prop 用字符串字面量联合类型（`status: 'ENABLED' | 'DISABLED'`）
- 布尔 prop 避免互斥组合（`isEdit + isView` → 改用 `mode: 'edit' | 'view' | 'create'`）

### 6.2 Emits

```typescript
const emit = defineEmits<{
  search: [];
  reset: [];
  'page-change': [pageNum: number];
  offline: [record: ProductRecord];
}>();
```

- 事件名用 kebab-case（`page-change`、`status-change`）
- 事件语义体现用户操作，不是数据变化（`@offline` 而不是 `@status-update`）
- 回调参数类型明确，不传裸 `any`

---

## 7. 页面级模式

### 7.1 列表页

典型组件组合：

```text
views/product/list.vue
├── ProductSearchForm.vue      # 筛选栏（含状态 Tab）
├── ProductTable.vue           # 表格（含分页、排序、批量操作）
├── ProductOfflineConfirmModal # 下架确认弹层
└── ProductExportModal         # 导出弹层
```

Page 只管：弹层 open/close + 弹层 loading；列表数据逻辑全部在 composable。

筛选栏约定：
- 有"草稿"状态（`draftQuery`）和"已提交"状态（`query`）区分
- 点击搜索才把 draftQuery 同步到 query 并发起请求
- 重置同时清空 draftQuery 和 query，pageNum 回 1

### 7.2 详情页

典型组件组合：

```text
views/product/detail.vue
├── DcgjBread                  # 面包屑
├── ProductAuditBanner.vue     # 审核状态横幅（可选）
├── ProductInfoSectionCard.vue # 基本信息区块
├── ProductRichDetailSection.vue # 富文本区块
├── ProductSkuTable.vue        # SKU 表格
└── ProductDetailFooter.vue    # 操作区（审核通过/驳回/下架）
```

约定：
- 详情数据必须重新请求，不信任列表传参
- 字段为空时显示 `-`，不显示空白
- 资源不存在时提供明确提示

### 7.3 表单页

典型组件组合（参考 `views/merchant/form.vue`）：

```text
views/merchant/form.vue
├── DcgjBread
├── BasicInfoSection.vue        # 基础信息分区
├── BillingInfoSection.vue      # 结算信息分区
├── SettlementSection.vue
└── StickyFooter.vue            # 吸底操作栏（保存/取消）
```

约定：
- 大表单按业务语义拆成多个 Section 组件
- 编辑态进入时调详情接口回填，`useMerchantForm` / `usePriceRuleForm` 封装
- 提交中禁用提交按钮（`submitting` 状态）
- app-merchant 有 `useUnsavedChangesGuard` 未保存离开提示

---

## 8. 弹层模式

### 8.1 确认类 Modal

适用：单一操作确认（下架确认、状态变更确认）。

命名规则：`{Domain}ConfirmModal.vue` 或 `{Domain}StatusConfirmDialog.vue`。

```vue
<!-- 调用方：views 层持有 open 和 loading -->
<ProductOfflineConfirmModal
  :open="offlineConfirmOpen"
  :confirm-loading="offlineConfirmLoading"
  :product-name="offlineProductRecord?.productName || ''"
  @confirm="confirmOfflineProduct"
  @cancel="closeOfflineModal"
/>
```

### 8.2 详情/编辑 Drawer

适用：内容较多、需要保留主页面上下文（如价格规则详情面板 `PriceRuleDetailPanel`）。

使用 `DcgjDrawer`，宽度默认 925px，footer 自动间距。

### 8.3 弹层状态归属

- `open`、`confirmLoading`、`currentRecord` 放在调用该弹层的 views 层
- 弹层自身不持有这些状态（复用性更强）
- 弹层关闭时重置 `currentRecord`（避免快速切换时数据串）

---

## 9. 表单模式

### 9.1 表单分层

| 层级 | 示例 | 职责 |
|------|------|------|
| Form Composable | `useMerchantForm` | 状态、校验触发、提交请求 |
| Form Section | `BasicInfoSection.vue` | 一组相关字段，通过 v-model 或 emit 与父层通信 |
| 字段级组件 | `IdCardUploadGroup.vue` | 高度复合的单字段封装 |

### 9.2 表单状态约定

- 临时输入：`formState` 放在 composable 的 `reactive` 里
- 字段枚举选项：composable 内调接口获取，传给 Section 作 prop
- 提交结果：由 composable 调用 API，成功后由 views 层执行跳转

### 9.3 校验

- 使用 Ant Design Vue / dcgj-ui 的 Form 校验机制
- 后端校验失败的字段错误，映射到对应字段（不只弹 toast）
- 大表单分节后，提交时统一触发所有节的校验

---

## 10. 表格模式

### 10.1 组件拆分

| 组件 | 说明 |
|------|------|
| `{Domain}Table.vue` | 主表格，含列定义、分页、排序、行操作 |
| `{Domain}SearchForm.vue` | 筛选栏，emit `search`/`reset`/`status-change` |
| `{Domain}StatusSelect.vue` | 可复用状态下拉（需要时单独拆出） |

列定义直接写在 Table 组件的 `<script setup>` 里（`const columns = [...]`），不单独建 `columns.ts`（除非列定义超过 50 行或需要动态生成）。

### 10.2 分页与筛选约定

- 分页变化通过 emit `page-change` 通知 views，views 调 composable 的 `changePage`
- 筛选提交时 pageNum 重置为 1
- 删除最后一条后退回上一页（composable 里判断 `pageNum > totalPages`）

---

## 11. 通用基础组件模式

### StatusTag

`components/common/StatusTag.vue` — 接收 `type`（状态类型名，如 `'product-status'`）和 `value`（枚举值），根据 `STATUS_LABEL` 常量渲染对应文案和颜色。

新增状态类型时：在 StatusTag 内扩展类型映射，不要在各页面各自渲染状态文案。

### PriceText / DcgjNumber

金额展示统一用 `PriceText.vue`（内部调 `DcgjNumber`）或直接用 `DcgjNumber`，不手写千分位格式化。

### CommonRemotePagedSelect

远程分页搜索下拉，封装了 loading/空态/防抖，避免每个远程搜索都重新实现。

---

## 12. 何时抽共享组件

只有同时满足以下条件才抽到 `components/common/`：

- 在 **两个以上**域内真实复用（不是"将来可能"）
- 抽象后命名自然清晰，不包含具体业务上下文
- 不需要依赖单领域的特定数据结构

否则先保持在 `components/{domain}/` 内，延迟抽象。

---

## 13. 常见反模式

- 在 `views/` 里直接调用 `api/` 函数
- 在 `components/` 里 `import { useRouter }` 并直接跳转路由
- Modal 的 open/loading 状态放在 Modal 组件内部（无法被父层控制）
- 在列定义的 `customRender` 里写大量请求和业务判断
- 状态标签在不同页面颜色/文案不一致（未走 StatusTag）
- `composable` 返回了 50+ 个字段，暗示职责过多

---

## 14. 推荐的决策顺序

新增功能块时，按此顺序思考：

1. 它属于 views（路由入口）、域内组件，还是 `components/common/`
2. 是否有同类实现可以参考或复用
3. 它的数据逻辑放 composable，还是就地写（只被用一次的简单逻辑可以就地写）
4. 它的 props/emit 设计是否最小化
5. 弹层状态由谁持有
6. 是否涉及危险区域（`11_DANGEROUS_AREAS.md`）

---

## 15. 真实性校验

- [x] 组件目录路径已对照真实代码验证
- [x] 组件语法（`<script setup lang="ts">`）已确认
- [x] Composable 命名规则已从真实文件提取
- [x] 无 `features/` 和 `shared/` 目录已确认
- [x] 页面组件结构已对照 `views/product/list.vue` 验证
- [x] 最后校验日期已更新（2026-05-08）