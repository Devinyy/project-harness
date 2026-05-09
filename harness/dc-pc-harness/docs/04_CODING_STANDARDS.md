# 04_CODING_STANDARDS.md

---
owner: Frontend Team
last_verified: 2026-05-08
status: active
purpose: 统一代码风格、命名方式、类型约束、样式书写、错误处理和可维护性要求，让多人协作保持一致。
primary_readers:
  - Frontend Developers
  - Reviewers
  - AI Agents
related:
  - 02_ARCHITECTURE.md
  - 07_API_CONTRACTS.md
  - 11_DANGEROUS_AREAS.md
---

## 1. 总体原则

1. **可读优先于炫技**
2. **一致性优先于个人偏好**
3. **显式优先于隐式**（类型、错误处理、状态）
4. **类型明确，拒绝无理由 `any`**
5. **复用优先于复制**
6. **贴近当前项目约束，不强行套外部最佳实践**

---

## 2. 格式化规范（Prettier 强制执行）

`.prettierrc.json` 配置如下，**不允许手动覆盖**：

```json
{
  "singleQuote": true,
  "trailingComma": "all",
  "endOfLine": "auto",
  "printWidth": 100,
  "proseWrap": "never",
  "arrowParens": "avoid",
  "htmlWhitespaceSensitivity": "ignore",
  "vueIndentScriptAndStyle": true
}
```

关键规则：

| 规则 | 结果 |
|------|------|
| `singleQuote: true` | 字符串用单引号 `'` |
| `trailingComma: "all"` | 函数参数、数组、对象末尾都加逗号 |
| `printWidth: 100` | 行宽 100，超出自动折行 |
| `arrowParens: "avoid"` | 单参数箭头函数不加括号：`x => x` 而非 `(x) => x` |
| `vueIndentScriptAndStyle: true` | Vue SFC 的 `<script>` 和 `<style>` 内容统一缩进 |

---

## 3. 命名规范

### 3.1 文件命名

| 文件类型 | 规范 | 示例 |
|---------|------|------|
| Vue 组件 | `PascalCase.vue` | `StatusTag.vue`, `ProductSearchForm.vue` |
| Composable | `useXxx.ts` | `useProductListQuery.ts` |
| API 文件 | `domain.ts` | `product.ts`, `merchant.ts` |
| API mapper | `domain.xxx.mapper.ts` | `merchant.detail.mapper.ts` |
| API 类型定义 | `domain.definitions.ts` | `merchant.definitions.ts` |
| 页面级类型 | `types/domain.ts` | `types/product.ts`, `types/price-rule.ts` |
| 工具函数 | `camelCase.ts` | `download.ts`, `price.ts` |
| 常量/枚举 | 与类型文件合并，或 `constants/` | `product.ts` 中导出 `PRODUCT_STATUS_LABEL` |

### 3.2 变量与类型命名

| 类别 | 规范 | 示例 |
|------|------|------|
| 变量 / 函数 | `camelCase` | `queryProducts`, `selectedIds` |
| 常量（不变值）| `UPPER_SNAKE_CASE` | `PRODUCT_STATUS_LABEL`, `PRICE_RULE_DEFAULT_QUERY` |
| 类型 / 接口 | `PascalCase` | `ProductRecord`, `PriceRuleStatus` |
| 枚举字面量 | 与后端契约一致 | `'ENABLED'`, `'NOT_STARTED'`, `1`, `2` |
| 布尔值 | `is / has / can` 前缀 | `isLoading`, `batchMode`, `hasPermission` |
| 事件处理函数 | `handle` 或 `on` 前缀 | `handleSubmit`, `onBatchOffline`, `onExport` |
| Vue 组件名 | `PascalCase` | `<ProductTable />`, `<StatusTag />` |

### 3.3 反例（避免）

```typescript
// ❌ 语义模糊
const data = ref([])
const info = {}
const item2 = ...
let flag = false

// ✅ 语义明确
const products = ref<ProductRecord[]>([])
const merchantDetail = {} as MerchantDetailData
const selectedProduct = ...
const isLoading = ref(false)
```

---

## 4. TypeScript 规范

### 4.1 TypeScript 配置

`tsconfig.base.json`（所有 app 继承）：

```json
{
  "compilerOptions": {
    "target": "ESNext",
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "strict": true,
    "skipLibCheck": true,
    "isolatedModules": true,
    "noEmit": true
  }
}
```

**`strict: true` 已开启**，包含：`strictNullChecks`、`noImplicitAny`、`strictFunctionTypes` 等。

### 4.2 类型 import

使用 `import type` 导入纯类型，避免运行时副作用：

```typescript
// ✅ 正确
import type { ProductRecord, ProductStatus } from '@/types/product';
import { PRODUCT_STATUS_LABEL } from '@/types/product';

// ❌ 不推荐（类型和值混在一个 import）
import { ProductRecord, PRODUCT_STATUS_LABEL } from '@/types/product';
```

### 4.3 禁止滥用 `any`

- 公共函数、API 层、Composable、store 中**不允许**使用 `any`
- 现有代码中部分 `any` 是历史遗留（如 `merchant.ts` 中的 `request<any>`），不推荐继续扩散
- 确实无法建模时，用 `unknown` + 类型守卫，或临时 `// eslint-disable-next-line @typescript-eslint/no-explicit-any` 并附说明

### 4.4 类型放置规则

| 类型范围 | 放置位置 |
|---------|---------|
| 接口原始请求/响应类型 | `api/domain.definitions.ts` |
| UI 展示用领域类型 | `types/domain.ts` |
| 跨 app 共享基础类型 | `packages/shared-types/src/index.ts` |
| 组件 Props 类型 | 与组件同文件，`defineProps<{...}>()` |
| Composable 内部类型 | 与 composable 同文件 |

### 4.5 联合类型与字面量类型

优先使用联合类型替代魔法字符串：

```typescript
// ✅ 项目现用方式
type MerchantStatus = 'ENABLED' | 'DISABLED' | 'PENDING';
type ProductStatus = 1 | 2 | 3 | 4;
type PriceRuleDimension = 'PRODUCT' | 'BRAND' | 'CATEGORY';

// ❌ 不推荐
const status = 'ENABLED';  // 无类型约束
```

---

## 5. Vue 组件规范

### 5.1 组件写法

统一使用 `<script setup lang="ts">`（Composition API + TypeScript）：

```vue
<template>
  <!-- 模板内容 -->
</template>

<script setup lang="ts">
  import { ref, computed } from 'vue';
  import type { ProductRecord } from '@/types/product';

  const props = defineProps<{
    products: ProductRecord[];
    loading: boolean;
  }>();

  const emit = defineEmits<{
    detail: [record: ProductRecord];
    offline: [record: ProductRecord];
  }>();
</script>

<style scoped>
  /* 局部样式 */
</style>
```

### 5.2 `<script setup>` 内部顺序

推荐顺序：

1. `import`（外部库 → `@/` 路径别名 → 相对路径）
2. `defineProps` / `defineEmits`
3. 常量
4. `ref` / `reactive` 状态
5. `computed` 派生状态
6. `watch` / `watchEffect`
7. 生命周期钩子
8. 函数（handlers / methods）

### 5.3 Props 定义

用 TypeScript 泛型定义，不使用运行时选项式语法：

```typescript
// ✅
const props = defineProps<{
  kind: 'status' | 'source' | 'rule-status';
  value: ProductDisplayStatus | ProductSource;
}>();

// ❌ 不推荐
const props = defineProps({
  kind: String,
  value: [Number, String],
});
```

### 5.4 模板规范

- 属性多时每行一个，按字母序或语义序排列
- 事件命名用 `kebab-case`（`@status-change`、`@page-change`）
- 避免在模板中写复杂逻辑，抽到 `computed` 或函数
- 空态、loading 态必须显式处理

```vue
<!-- ✅ 属性多时换行，事件用 kebab-case -->
<ProductTable
  :batch-mode="batchMode"
  :loading="loading"
  :products="products"
  @offline="openOfflineModal"
  @page-change="changePage"
/>

<!-- ❌ 所有属性堆一行 -->
<ProductTable :batchMode="batchMode" :loading="loading" @offline="openOfflineModal" />
```

### 5.5 组件目录组织

```text
components/
├── common/          # 无业务依赖、可跨子路由复用的组件
│   ├── StatusTag.vue
│   └── PriceText.vue
├── product/         # 商品域业务组件
│   ├── ProductTable.vue
│   └── ProductSearchForm.vue
└── price-rule/      # 价格规则域业务组件
    ├── PriceRuleTable.vue
    └── PriceRuleDetailPanel.vue
```

---

## 6. Composable 规范

### 6.1 结构约定

```typescript
export function useXxx(options?: XxxOptions) {
  // 1. 状态
  const loading = ref(false);
  const data = ref<XxxRecord[]>([]);

  // 2. 派生状态
  const total = computed(() => ...);

  // 3. 副作用
  watch(...);

  // 4. 方法（不导出的内部方法写在这里）
  async function fetchData() { ... }
  function handleReset() { ... }

  // 5. 返回（只暴露外部需要的内容）
  return {
    loading,
    data,
    total,
    onReset: handleReset,
  };
}

// 纯工具函数放在 composable 函数体外部
function buildRouteQuery(query: XxxQuery) { ... }
```

### 6.2 命名规范

- Composable 文件和函数统一 `useXxx` 前缀
- 按功能分文件，不把多个不相关 composable 写在同一文件
- 返回的方法名体现语义：`onExport`、`search`、`reset`、`changePage`

### 6.3 异步处理

```typescript
// ✅ try/catch + finally 管理 loading 状态
async function fetchProducts() {
  loading.value = true;
  try {
    const result = await queryAdminProductPage(req);
    products.value = result.records || [];
  } catch {
    products.value = [];
  } finally {
    loading.value = false;
  }
}

// ✅ 不需要等待结果的调用加 void
void fetchFilterOptions();

// ❌ 不处理异常
const result = await queryAdminProductPage(req); // 若报错直接崩溃
```

---

## 7. API 层规范

### 7.1 文件分工

| 文件 | 职责 |
|------|------|
| `api/domain.ts` | 对外导出的接口函数（`async function queryXxx`） |
| `api/domain.definitions.ts` | 接口原始请求/响应类型 |
| `api/domain.query.mapper.ts` | 请求参数转换（UI 状态 → API 参数） |
| `api/domain.detail.mapper.ts` | 响应数据转换（API 响应 → UI 类型） |

### 7.2 接口函数规范

```typescript
// ✅ 命名清晰、返回明确类型
export async function getMerchantDetail(id: string): Promise<MerchantDetailData> {
  const result = await request<ShopDetailRespVO>({
    method: 'GET',
    url: '/ops/v1/shop/query-detail',
    params: { shopId: id },
  });
  return mapServerShopDetailToMerchant(result);
}

// ❌ 裸调 axios、无类型
const res = await axios.get('/ops/v1/shop/query-detail?shopId=' + id);
```

### 7.3 错误处理约定

- API 函数本身**不处理** UI 反馈（不调 `message.error`）
- 让 composable 或 views 决定如何展示错误
- 特例：对可预期的 fallback（如选项接口失败返回默认值），可在 API 层 catch 并返回 fallback

---

## 8. 样式规范

### 8.1 样式方案

- 使用 **Sass（`.scss`）** 编写样式
- Vue 组件内使用 `<style scoped>` 局部样式，避免污染全局
- CSS class 命名：`kebab-case`（如 `product-list`、`product-status-tag`）
- 状态修饰符：`is-` 前缀（如 `is-status-2`、`is-rule-status-active`）

### 8.2 颜色与设计 Token

- 优先使用 CSS 变量（如 `var(--product-primary)`）
- 不随意硬编码大量十六进制色值，特别是与业务状态无关的通用颜色
- dcgj-ui / ant-design-vue 的 token 变量优先于自定义变量

### 8.3 禁止事项

- 在 `<style>` 中省略 `scoped`（会污染全局）
- 在 `<style scoped>` 中用 `!important` 覆盖 dcgj-ui 组件样式（应用深度选择器 `:deep()`）
- 在全局样式中写局部业务特定样式

---

## 9. Import 规范

### 9.1 导入顺序（ESLint import 插件强制）

1. 第三方库（`vue`、`dcgj-ui`、`@ant-design/icons-vue` 等）
2. `@platform/*` 内部包
3. `@/` 路径别名（当前 app 内部）
4. 相对路径（`./`、`../`）
5. 样式文件（最后）

### 9.2 路径别名

| 别名 | 指向 |
|------|------|
| `@` | `./src`（各 app 内部） |
| `@platform/http-client` | `packages/http-client/src/index.ts` |
| `@platform/micro-bridge` | `packages/micro-bridge/src/index.ts` |
| `@platform/shared-types` | `packages/shared-types/src/index.ts` |
| `@platform/shared-utils` | `packages/shared-utils/src/index.ts` |

禁止跨 app 相对路径引用（如 `../../app-merchant/src/...`）。

---

## 10. 错误处理规范

### 10.1 原则

- 错误必须被**显式捕获**，不允许 `catch {}` 什么都不做
- 用户可感知的错误要给出合适反馈（`message.error`）
- Composable 中 catch 后要重置相关状态（如 `data.value = []`）

### 10.2 项目中已有的 HTTP 错误处理

- `@platform/http-client` 内置了全局错误 toast（业务码非 0 时自动提示）
- 页面层只处理**需要特殊展示**的错误，不要重复提示
- 401 → token 刷新由 http-client 和 micro-bridge 自动处理，不在业务层重复处理

### 10.3 禁止事项

- `catch` 后什么都不做（静默吞错）
- 在 API 层和 Composable 层都调用 `message.error`（重复提示）
- 用 `console.log` 替代错误处理

---

## 11. 注释规范

- 注释解释**为什么**，而不是重复**做了什么**
- 以下情况**必须**有注释：
  - 绕过类型系统（`// eslint-disable`、`as any`）时说明原因
  - 历史兼容代码注明移除条件
  - 复杂的业务规则或状态流转逻辑
- 不要写和代码内容完全相同的注释：

```typescript
// ❌ 没有信息量
// 获取产品列表
async function fetchProducts() { ... }

// ✅ 解释为什么
// 后端分页从 1 开始，路由参数可能为 0，需要 max 保护
pageNum: Math.max(pageNum, 1),
```

---

## 12. Git 提交规范（Commitlint 强制执行）

格式：`<type>(<scope>): <subject>`

允许的 `type`：

| type | 用途 |
|------|------|
| `feat` | 新功能 |
| `fix` | Bug 修复 |
| `docs` | 文档变更 |
| `style` | 代码格式（不影响功能） |
| `refactor` | 代码重构 |
| `test` | 测试相关 |
| `chore` | 构建/工具变更 |
| `revert` | 回滚提交 |

示例：

```
feat(app-product): 新增价格规则列表页
fix(app-merchant): 修复商家列表分页重置问题
chore(.gitignore): 更新 gitignore 文件
refactor(app-product): 更新价格规则适配器以反映新的状态字段
```

---

## 13. 提交前自检清单

每次提交前确认：

- [ ] `pnpm run validate` 通过（typecheck + lint）
- [ ] `pnpm run stylelint` 通过
- [ ] 无无理由的 `any`
- [ ] 空态 / loading / error 已处理
- [ ] Vue 组件 `<style>` 有 `scoped`
- [ ] 跨 app 无非法 import
- [ ] 危险区改动已自检（见 `11_DANGEROUS_AREAS.md`）
- [ ] 必要时已更新 docs/

---

## 14. 禁止清单

- 在 `views/` 或 `<template>` 中裸调接口（必须通过 `api/` 层）
- 跨 app 直接 import（`../../app-xxx/src/...`）
- 在 API 层调用 UI 反馈（`message.error`）
- 使用 Options API（统一 `<script setup>`）
- 使用 `var` 声明变量
- 在 `<style>` 中省略 `scoped`
- 把一次性需求强行抽象成全局 shared 组件
- 修改 `packages/*` 公共包而不评估影响面

---

## 15. 真实性校验

- [x] Prettier 配置来自 `.prettierrc.json`
- [x] TypeScript strict 配置来自 `tsconfig.base.json`
- [x] 命名规范来自真实代码（`StatusTag.vue`、`useProductListQuery.ts` 等）
- [x] Commit 类型来自 `commitlint.config.mjs`
- [x] 组件写法基于真实 `.vue` 文件提取
- [x] 本文档最后校验日期：2026-05-08
