# 07_API_CONTRACTS.md

---
owner: Frontend Team + Backend Team
last_verified: 2026-05-08
status: active
purpose: 统一前端项目中的接口组织方式、字段模型、适配逻辑、错误处理、缓存与 Mock 策略，让 API 接入方式保持一致。
primary_readers:
  - Frontend Developers
  - Backend Developers
  - QA
  - AI Agents
related:
  - 02_ARCHITECTURE.md
  - 03_BUSINESS_DOMAIN.md
  - 04_CODING_STANDARDS.md
  - 08_TASK_PLAYBOOKS.md
  - 11_DANGEROUS_AREAS.md
---

## 0. 当前项目采用情况

- 是否适用：**是**
- 真实请求封装入口：各 app 的 `src/request/index.ts`（对外暴露 `request` 函数），底层调用 `@platform/http-client`
- 真实 API 目录：各 app 的 `src/api/`（**不叫 `services/`**）
- 真实 API 类型目录：`src/api/domain.definitions.ts` 和 `src/types/domain.ts`
- 真实 Mock 方案：**暂无** Mock 系统，开发直连测试环境 API（`admin-api-test.dachuguanjia.com`）
- 不要使用的目录或写法：
  - `services/`（本项目 API 层叫 `api/`，不叫 `services/`）
  - 在 `views/` 或 `composables/` 中直接 `import axios`
  - 在 API 层直接 `new axios()`（必须使用 `@/request` 暴露的 `request` 实例）
- 与模板不同的地方：
  - API 目录是 `api/`，不是 `services/`
  - 分层是 `api/domain.ts`（接口函数）+ `api/domain.definitions.ts`（DTO 类型）+ `api/domain.xxx.mapper.ts`（转换函数）
  - 契约测试放在 `api/__contracts__/`（TypeScript 编译期检查，不是 runtime 测试）

---

## 1. 接口分层

```text
@/request（Axios 实例，来自 @platform/http-client）
    ↓
api/domain.ts（接口函数：queryXxx / getXxx / saveXxx）
    ↓
api/domain.xxx.mapper.ts（请求构建 buildXxxReq / 响应映射 mapXxx）
    ↓
composables/useXxx.ts（请求状态管理、loading、错误处理）
    ↓
views/*.vue（触发动作、消费数据）
```

**禁止**：

- 在 `views/` 中直接调用 `request(...)` 或 `axios(...)`
- 在 `api/` 层调用 `message.error` 等 UI 反馈
- 在 mapper 中包含路由跳转或权限判断
- 多个页面重复手写相同的字段转换逻辑

---

## 2. 请求入口

每个 app 的 `src/request/index.ts` 暴露一个 `request` 函数：

```typescript
// 正确使用方式
import request from '@/request';

export async function queryMerchantList(params: MerchantListQuery) {
  const result = await request<PageResult<ShopQueryRespVO>>({
    method: 'POST',
    url: '/ops/v1/shop/query-page',
    data: buildShopQueryReqVO(params),
  });
  return result;
}
```

底层 `@platform/http-client` 已内置：

- 请求头自动注入 token（`Authorization: Bearer <token>`）
- token 过期预检查（JWT decode，30 秒阈值）
- 401 响应自动刷新 token 并重试一次
- 业务码非 0 时自动弹 toast 错误提示
- 大整数（BigInt）自动转 string 避免 JSON 解析精度丢失

---

## 3. 基础响应结构

### 3.1 标准接口响应（@platform/shared-types）

```typescript
interface BaseResponse<T = unknown> {
  code: string | number;  // 0 或 '0' 表示成功
  message: string;
  data: T;
}
```

### 3.2 分页响应（MyBatis-Plus 风格）

```typescript
interface PageResult<T> {
  current: number;   // 当前页（从 1 开始）
  pages: number;     // 总页数
  records: T[];      // 当前页数据
  size: number;      // 每页条数
  total: number;     // 总记录数
}
```

**注意**：

- 分页从 **1** 开始（`pageNum: 1`），不是 0
- 参数名是 `pageNum` 和 `pageSize`（不是 `page` 和 `limit`）
- 总数字段是 `total`（不是 `count`）
- 删除当前页最后一条后，需要把 `pageNum` 回退至 `Math.max(1, currentPage - 1)` 再重新查询

### 3.3 实际接口包装差异

部分历史接口的响应结构不统一，可能出现：

- `{ data: PageResult<T> }` — 标准结构
- 直接返回 `PageResult<T>` — 省略外层包装
- `{ data: { records, total } }` — 简化结构

处理方式：在 mapper 中做兼容，不要在 composable 层重复写判断：

```typescript
// adapter 内处理包装差异
const pageData = ('data' in result ? result.data : result) as PageResult<T>;
```

---

## 4. api/ 目录规范

### 4.1 文件职责分工

| 文件 | 职责 |
|------|------|
| `api/domain.ts` | 导出的接口函数（`queryXxx`、`getXxx`、`saveXxx`、`updateXxx`） |
| `api/domain.definitions.ts` | 原始 API DTO 类型（后端字段名），以及无法归入 types/ 的接口专属类型 |
| `api/domain.query.mapper.ts` | UI 查询状态 → API 请求参数转换（`buildXxxReq`） |
| `api/domain.detail.mapper.ts` | API 响应 → UI 展示类型转换（`mapXxx`） |
| `api/__contracts__/domain.contract.ts` | TypeScript 编译期契约检查（不是 runtime 测试） |

### 4.2 接口函数命名约定

动词 + 领域对象，参照已有函数：

| 用途 | 命名示例 |
|------|---------|
| 分页查询 | `queryMerchantList`、`queryAdminProductPage` |
| 单条查询 | `getMerchantDetail`、`getMarkupRuleDetail` |
| 新建 | `addShop`、`saveMarkupRule` |
| 编辑 | `editShop`、`updateMarkupRule` |
| 状态变更 | `updateMerchantStatus`、`toggleMarkupRule` |
| 批量操作 | `batchUpdateMerchantStatus`、`batchOffShelfProducts` |
| 导出 | `exportMerchantList`、`exportAdminProductList` |

**禁止**：`fetchData`、`getList`（缺乏领域语义）

---

## 5. 请求参数构建（buildXxxReq）

接口函数不直接消费 UI 的 `query` 对象，而是先通过 `buildXxxReq` 构建 API 请求参数：

```typescript
// api/product.ts 中使用
export function buildAdminProductPageReq(query: ProductQuery): AdminProductPageReq {
  return stripEmpty({
    pageNum: query.pageNum,
    pageSize: query.pageSize,
    spuId: query.spuId || undefined,
    status: query.status === 'ALL' ? undefined : query.status,
    // ...
  });
}

// composable 中调用
const result = await queryAdminProductPage(buildAdminProductPageReq(query));
```

`stripEmpty` 工具函数（本项目内各 adapter 自行实现）：过滤掉值为 `undefined` 或 `''` 的字段，避免发送多余参数：

```typescript
function stripEmpty<T extends Record<string, unknown>>(value: T): T {
  return Object.fromEntries(
    Object.entries(value).filter(([, item]) => item !== undefined && item !== ''),
  ) as T;
}
```

---

## 6. 响应映射（mapper / adapter）

### 6.1 职责

mapper 负责：

- 字段重命名（后端 `ruleName` → 前端 `ruleName`，无变化可直传）
- 后端数字枚举 → 前端字符串枚举（`dimension: 1 → 'PRODUCT'`）
- 空值兜底（`rule.ruleName || '-'`、`Number(rule.markupValue || 0)`）
- 兼容后端返回格式不一致（数组/对象/null 归一化）

mapper 不负责：

- UI 提示（`message.error`）
- 路由跳转
- 权限判断

### 6.2 典型模式

```typescript
// 后端数字枚举 → 前端字符串枚举
function mapDimension(dimension?: number): PriceRuleDimension {
  const dimensionMap: Record<number, PriceRuleDimension> = {
    1: 'PRODUCT',
    2: 'BRAND',
    3: 'CATEGORY',
  };
  return dimensionMap[Number(dimension)] || 'PRODUCT';  // 带默认值兜底
}

// 空值兜底
id: String(rule.id || ''),
ruleName: rule.ruleName || '-',
value: Number(rule.markupValue || 0),
```

### 6.3 何时不需要 mapper

如果后端字段与前端 UI 类型完全一致，可省略 mapper，直接使用后端类型。但一旦需要：

- 数字枚举 → 字符串枚举
- 多个字段合并或拆分
- 兼容不统一的后端结构

则必须建 mapper，**不允许在 composable 或 views 中散落转换代码**。

---

## 7. 枚举值映射规则

本项目存在后端数字枚举和前端字符串枚举并存的情况，**前端内部统一使用字符串枚举**，在 mapper 层做转换：

| 接口字段（数字） | 前端枚举（字符串） | 常量文件 |
|---------|---------|---------|
| `dimension: 1/2/3` | `'PRODUCT'/'BRAND'/'CATEGORY'` | `PriceRuleDimension` |
| `markupType: 1/2` | `'FIXED'/'RATE'` | `PriceRuleMethod` |
| `syncStatus: 0/1` | `'IMPORTING'/'COMPLETED'` | `PriceRuleSyncStatus` |
| `status: 1/2/3/4` | `1/2/3/4`（商品直接用数字） | `ProductStatus` |
| `status: 'ENABLED'/'DISABLED'/'PENDING'` | 同名字符串 | `MerchantStatus` |

展示文案统一在 `types/` 文件中通过 `XXX_LABEL` 常量管理：

```typescript
// ✅ 正确：从常量取文案
PRODUCT_STATUS_LABEL[record.status]  // '已上架'

// ❌ 禁止：在模板或 composable 中散写
record.status === 2 ? '已上架' : '...'
```

---

## 8. 错误处理

### 8.1 分层职责

| 层级 | 职责 |
|------|------|
| `@platform/http-client` | 网络错误、超时、401 刷新重试、业务码非 0 自动 toast |
| `api/domain.ts` | 识别空数据结构，throw 明确错误 |
| `composables/useXxx.ts` | try/catch，重置 loading/data，特殊错误展示 |
| `views/*.vue` | 仅处理需要特殊 UI 表现的错误（如表单字段级错误） |

### 8.2 API 层错误约定

接口函数在以下情况 throw：

```typescript
// 关键数据为空时主动抛出，让上层感知
if (!detail?.basicInfo) {
  throw new Error('Merchant detail payload is empty');
}
```

对可预期的 fallback（如选项接口失败），可在 catch 中返回默认值：

```typescript
// 选项接口失败返回 fallback，不让页面崩溃
try {
  const result = await queryMerchantTypeOptions();
  return result;
} catch {
  return fallbackMerchantTypeOptions;
}
```

### 8.3 禁止事项

- `catch {}` 什么都不做（静默吞错）
- 在 `api/` 层和 `composables/` 层都调用 `message.error`（重复提示）
- HTTP Client 已处理的业务码错误在页面层再次 catch 提示（会导致双重弹窗）

---

## 9. 分页、筛选、排序约定

### 9.1 分页参数

```typescript
// 请求：pageNum（从 1 开始）+ pageSize
{ pageNum: 1, pageSize: 10 }

// 响应：PageResult<T>
{ current, pages, records, size, total }
```

### 9.2 筛选参数

- 空筛选条件用 `undefined`（经 `stripEmpty` 过滤掉，不发送空字符串）
- 全部状态用 `undefined`（不传 status，而非传 `'ALL'`）
- 枚举筛选值与后端约定保持一致（商品状态传数字 `1/2/3/4`，商家状态传字符串 `'ENABLED'`）

### 9.3 排序参数

```typescript
// 商品列表排序
{ sortBy: 'createTime' | 'settlementPrice' | 'salePrice' | 'margin', sortOrder: 'asc' | 'desc' }
```

### 9.4 删除最后一条后的处理

```typescript
// composable 中检查当前页是否超出
if (query.pageNum > totalPages.value) {
  syncRoute({ ...query, pageNum: totalPages.value });
}
```

---

## 10. 时间、金额、数值规范

### 10.1 时间

- 接口返回格式：字符串（`'2026-04-22 10:21'`），非时间戳
- 前端直接展示，**无需**转换时区（系统无多时区需求）
- 如需格式化，使用 `@platform/shared-utils` 中的 date 工具函数

### 10.2 金额与价格

- `settlementPrice`（结算价）、`salePrice`（销售价）、`marketPrice`（市场价）：单位均为**元**，保留两位小数
- `margin`（毛利率）：百分比数值，如 `24.32` 表示 `24.32%`
- `value`（价格规则加价值）：`FIXED` 类型单位为元，`RATE` 类型为百分比（<!-- TODO: 确认精度和单位 -->）
- 展示时使用 `PriceText` 组件（`apps/app-product/src/components/common/PriceText.vue`）

### 10.3 数值精度

- 大整数字段（如 ID）：`@platform/http-client` 已自动处理 JSON 解析精度问题（bigint → string）
- 前端不做二次处理，直接使用字符串 ID

---

## 11. 文件上传 / 导出

### 11.1 文件上传

- 使用七牛云直传（`qiniu-js`），不经过业务 API 网关
- 上传 token 由接口获取（`api/qiniu.ts`）
- 上传进度由 `DcgjUpload` 组件封装处理

### 11.2 列表导出

导出接口有两种模式，需在 adapter 层兼容处理：

```typescript
// 模式 A（旧）：接口直接返回文件流（blob）
// 模式 B（新）：接口返回 JSON，其中包含 downloadUrl

// merchant.ts 中已实现自动兼容逻辑
const isJsonResponse = contentType.includes('application/json');
if (isJsonResponse) {
  // 解析 downloadUrl 再下载
} else {
  // 直接用 blob
}
```

发送导出请求时需指定 `responseType: 'blob'` 和 `rawResponse: true`（绕过 http-client 的统一响应处理）：

```typescript
const response = await service.post(url, params, {
  responseType: 'blob',
  rawResponse: true,
} as any);
```

---

## 12. 契约测试（`__contracts__/`）

本项目在 `api/__contracts__/` 中放置 TypeScript 编译期契约检查文件（不是 Vitest / Jest 测试）：

- 通过类型赋值检查 adapter 函数输入输出是否符合 UI 类型定义
- 通过 TypeScript 编译（`pnpm run validate`）验证
- 新增 adapter 函数后，建议同步新增契约测试

```typescript
// 示例：__contracts__/product.contract.ts
const req: AdminProductPageReq = buildAdminProductPageReq({
  ...PRODUCT_DEFAULT_QUERY,
  status: 2,
});
void req; // 确保 TypeScript 检查生效
```

---

## 13. 鉴权与上下文

详见 `11_DANGEROUS_AREAS.md` 第 2.3 节（认证与 Token 管理）。

关键点：

- Token 由 `@platform/http-client` 自动注入请求头，业务代码无需手动处理
- 子应用的 token 从主基座（micro-main）通过 micro-bridge 获取，在 `request/tokenProvider.ts` 中注入
- 401 → 自动 refresh → 重试，由 http-client 统一处理

---

## 14. 真实性校验

- [x] API 目录结构来自 `apps/app-merchant/src/api/` 和 `apps/app-product/src/api/`
- [x] `PageResult<T>` 结构来自真实代码
- [x] 分页参数（pageNum 从 1 开始）已从代码中验证
- [x] mapper 模式来自 `product-price-rule.adapter.ts`
- [x] `stripEmpty` 工具模式来自真实代码
- [ ] 价格规则加价值单位（元/分/百分比精度）待确认
- [ ] 业务错误码表待补充（需后端提供）
