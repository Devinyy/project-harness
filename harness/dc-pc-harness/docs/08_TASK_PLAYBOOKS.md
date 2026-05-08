# 08_TASK_PLAYBOOKS.md

---
owner: Frontend Team
last_verified: 2026-05-08
status: active
purpose: 将常见开发任务拆成可执行步骤，让新增页面、接接口、修 Bug 时有统一打法，减少低级遗漏和重复踩坑。
primary_readers:
  - Frontend Developers
  - AI Agents
related:
  - 02_ARCHITECTURE.md
  - 04_CODING_STANDARDS.md
  - 07_API_CONTRACTS.md
  - 11_DANGEROUS_AREAS.md
---

## 1. 通用工作流

无论什么任务，先做以下 5 步：

1. **查文档**：阅读本文相关 Playbook + `02_ARCHITECTURE.md` 确认目录
2. **找现有实现**：在同 app 找最相似的页面/composable/api 文件作为参考
3. **列改动点**：确认需要新增/修改哪些文件，是否涉及危险区
4. **确认是否需要技术方案**：见下方判断标准
5. **开发 + 自测 + 更新 docs**

### 1.1 技术方案触发条件

满足以下任一条件，先出技术方案（`10_TECH_SOLUTION_PLAYBOOK.md`）再开发：

- 新增完整子应用或大型业务模块
- 同时影响多个 app 的公共逻辑（`packages/*`）
- 涉及复杂状态流转或跨页面状态共享
- 需要修改微前端通信协议或认证链路
- 重构公共组件影响多个调用方

### 1.2 AI 执行任务前的标准输出格式

```
任务目标：
参考文档：
复用点（现有哪些可复用）：
改动点（新增/修改哪些文件）：
风险点（是否涉及危险区）：
自测点：
是否需要技术方案：是 / 否
```

---

## 2. Playbook A：在子应用中新增列表页

适用于 `app-merchant`、`app-product`、`app-system` 中新增带筛选、分页、表格的列表页。

### 第一步：找参考

在同 app 的 `views/` 中找最相似的现有列表页。

- `app-product`：参考 `views/ops/product/list.vue` + `composables/ops/useOpsProductListQuery.ts`
- `app-merchant`：参考 `views/merchant/list.vue`

### 第二步：新增路由

在 `src/router/index.ts` 中添加新路由（Hash 模式）：

```typescript
{
  path: '/your-domain/list',
  component: () => import('@/views/your-domain/list.vue'),
}
```

> 注意：子应用路由只需配置在子应用自己的 router 中。菜单需在主基座后台配置，前端不硬编码菜单。

### 第三步：创建 API 层文件

在 `src/api/` 下新建：

```text
api/
├── domain.ts               # 接口函数（queryDomainList、exportDomainList 等）
├── domain.definitions.ts   # 原始 DTO 类型（后端字段名）
└── domain.query.mapper.ts  # buildDomainPageReq（UI 状态 → API 参数）
```

参照 `07_API_CONTRACTS.md` 第 4-5 节的规范。

### 第四步：创建类型文件

在 `src/types/domain.ts` 中定义 UI 类型：

```typescript
export type DomainStatus = 'ENABLED' | 'DISABLED';
export const DOMAIN_STATUS_LABEL: Record<DomainStatus, string> = { ... };
export interface DomainRecord { ... }
export interface DomainQuery { ... }
export const DOMAIN_DEFAULT_QUERY: DomainQuery = { pageNum: 1, pageSize: 10, ... };
```

### 第五步：创建 composable

命名规则因 app 而异：

- **app-product**：`src/composables/ops/useOps{Domain}ListQuery.ts`（如 `useOpsPriceRuleListQuery.ts`）
- **app-merchant**：`src/composables/use{Domain}Query.ts`（如 `useMerchantQuery.ts`）

查询列表的 composable 必须包含**路由同步**模式（以 URL 为真值驱动请求）：

```typescript
export function useOpsDomainListQuery() {
  const route = useRoute();
  const router = useRouter();
  const loading = ref(false);
  const records = ref<DomainRecord[]>([]);
  const total = ref(0);
  const query = reactive<DomainQuery>(readQueryFromRoute());
  const draftQuery = reactive<DomainQuery>({ ...query });

  watch(
    () => route.query,
    () => {
      Object.assign(query, readQueryFromRoute());
      Object.assign(draftQuery, query);
      void fetchList();
    },
    { immediate: true },
  );

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

  function search() {
    void router.replace({ query: buildRouteQuery({ ...draftQuery, pageNum: 1 }) });
  }

  function reset() {
    void router.replace({ query: buildRouteQuery({ ...DOMAIN_DEFAULT_QUERY }) });
  }

  return { loading, records, total, query, draftQuery, changePage, search, reset };
}
```

> 注意：筛选提交通过 `router.replace` 修改 URL，由 `watch(route.query)` 触发实际请求。不要在 composable 里同时维护 URL 和 reactive 状态两套真值。

### 第六步：创建页面组件

路径因 app 而异：

- **app-product**：`src/views/ops/{domain}/list.vue`，子组件放 `components/ops/{domain}/`
- **app-merchant**：`src/views/merchant/list.vue`，子组件放 `components/merchant/list/`

规则：

- 引入 composable，解构后直接传给子组件
- 弹层的 `open`/`loading`/`currentRecord` 状态在 views 层管理（不在 composable 里）
- 拆出 `{Domain}SearchForm.vue`、`{Domain}Table.vue`、`{Domain}XxxModal.vue` 等子组件
- 空态、loading、error 显式处理（不能只靠数据空了就不渲染）

### 第七步：自测检查

- [ ] 列表正常加载
- [ ] 筛选条件修改后正确重置 pageNum
- [ ] 删除最后一条后页码回退
- [ ] 刷新页面后状态恢复正确
- [ ] 空数据显示空态
- [ ] loading 期间有加载态
- [ ] 不同角色能看到菜单和页面（需后端配置菜单权限）

---

## 3. Playbook B：新增详情页

### 参考

- `app-product`：`views/ops/product/detail.vue` + `composables/ops/useOpsProductDetail.ts`

### 标准步骤

1. 确定详情入口来自哪个页面（路由跳转还是 drawer/modal）
2. 在 `src/router/index.ts` 新增路由（如 `/your-domain/detail/:id`）
3. 在 `api/domain.ts` 中新增 `getDomainDetail(id: string)` 函数
4. 在 `api/domain.detail.mapper.ts` 中实现响应 → UI 类型映射
5. 创建 composable（app-product：`useOps{Domain}Detail`；app-merchant：`use{Domain}Detail`），封装 loading、detail、fetchDetail
6. 在 `views/` 中创建页面，拆分 section 组件到 `components/{domain}/detail/`（app-merchant 风格）或 `components/ops/{domain}/`（app-product 风格）
7. 返回路径处理：`router.back()` 或固定跳回列表 URL

### 容易漏掉的点

- 列表传过来的数据不等于详情真值，必须重新请求详情接口
- 状态变更后（如审核通过），详情和列表都需要刷新
- 某些字段为空时要显示 `-` 而不是空白
- `id` 不存在或资源不存在时显示 404 提示

---

## 4. Playbook C：新增创建 / 编辑表单页

### 参考

- `app-merchant`：`views/merchant/form.vue`
- `app-product`：`views/ops/price-rule/form.vue`

### 标准步骤

1. 确定是独立页面表单还是 Drawer/Modal 表单
2. 在 `router/index.ts` 新增路由（如 `/your-domain/form/:id?`，`id` 可选表示新建/编辑复用）
3. 在 `api/domain.ts` 中新增 `saveDomain` / `updateDomain` 函数
4. 在 `types/domain.ts` 中定义 `DomainFormState`
5. 创建 composable（app-product：`useOps{Domain}Form`；app-merchant：`use{Domain}Form`），封装表单状态、校验、提交
6. 在 `views/` 创建页面，使用 `DcgjFormPro` 或手写表单；大表单拆分为 Section 组件（参考 `components/merchant/form/`）
7. 提交成功后跳转详情页或列表页
8. 编辑态：进入时调详情接口回填数据

### 容易漏掉的点

- 提交中要防重复点击（`submitting` 状态禁用按钮）
- 编辑时某些字段不可修改（展示但 disabled）
- 离开页面时如有未保存数据需提示（app-merchant 有 `useUnsavedChangesGuard`，app-product 暂无）
- 后端校验失败时错误要映射到对应表单字段

---

## 5. Playbook D：接入新接口

### 标准步骤

1. **查现有 api/ 文件**：确认是否已有同领域的文件，优先在已有文件中新增函数
2. **新增接口函数**（`api/domain.ts`）：

   ```typescript
   export async function queryXxx(params: XxxReq): Promise<XxxResult> {
     const result = await request<ApiResult<XxxRespVO>>({
       method: 'POST',
       url: '/ops/v1/xxx/query',
       data: params,
     });
     return mapXxx(unwrapApiData(result));
   }
   ```

3. **定义 DTO 类型**（`api/domain.definitions.ts`）：原始后端字段名
4. **实现 mapper**（`api/domain.xxx.mapper.ts`）：`buildXxxReq` + `mapXxx`
5. **更新 types/**：定义 UI 展示类型（`DomainRecord`、`DomainQuery` 等）
6. **在 composable 中调用**：不在 views 中直接调接口
7. **处理边界情况**：空数据、加载态、错误态
8. **（可选）补充契约测试**：在 `api/__contracts__/` 下添加 TypeScript 编译期类型断言，确保 mapper 输出与 UI 类型匹配（参见 `07_API_CONTRACTS.md` 第 8 节）

### 替换旧接口时额外步骤

8. 确认新接口字段与旧接口的差异（新增/删除/重命名字段）
9. 更新 mapper，保持 UI 类型不变（UI 类型稳定，mapper 消化差异）
10. 确认分页参数名、枚举值是否有变化
11. 回归受影响的所有页面

### 接口参数约定

- 空值用 `undefined`，经 `stripEmpty` 过滤（不传 `''` 或 `null`）
- 分页从 1 开始（`pageNum: 1`）
- 枚举用字符串（前端），mapper 层转数字（后端需要时）

---

## 6. Playbook E：修复 Bug

### 原则

修 bug 先找根因，不是"哪里报错改哪里"。

### 标准步骤

1. **复现**：明确触发条件、角色、环境、页面路径、操作步骤
2. **分类**：UI 渲染问题 / 数据问题 / 请求问题 / 状态问题 / 权限问题
3. **收集信息**：
   - 浏览器 Console 报错
   - Network 请求参数和响应
   - 当前 store 状态
   - 问题触发前的用户操作
4. **找根因**：查相关 composable、api、mapper，不要只看第一眼的报错行
5. **修根因**：优先修数据层/逻辑层，UI 层的修复通常是症状而非根因
6. **补保护**：空值/边界情况是否需要防御
7. **回归**：回归相关路径，不只测修复点

### Bug 修复说明建议包含

```
根因：
影响范围：
修复点（文件 + 行）：
回归点：
是否需要补文档：
```

### 常见 bug 分类

| 症状 | 优先查 |
|------|------|
| 列表加载空白 | api 函数错误处理、composable catch、PageResult 结构适配 |
| 状态标签显示 undefined | 枚举 label 常量是否覆盖所有值、mapper 是否正确映射 |
| 分页跳转错误 | pageNum 是否从 1 开始、总页数计算是否正确 |
| 表单回填失败 | 详情 mapper、composable fetchDetail 调用时机 |
| 保存成功但数据不更新 | 成功回调是否触发了 fetchList、router.replace 是否触发 watch |
| token 失效白屏 | 见 `11_DANGEROUS_AREAS.md` token 管理部分 |
| 子应用加载失败 | 见 `11_DANGEROUS_AREAS.md` 微前端通信部分 |

---

## 7. Playbook F：新增 Pinia Store

仅在以下情况新增 store，**不要因为方便**就提升状态到全局：

- 状态需要跨多个 composable 或页面共享
- 状态需要在路由切换后保持
- 状态需要被多个非父子关系组件订阅

### 标准步骤

1. 确认不能用 composable 的 `ref/reactive` 或路由参数解决
2. 在 `src/stores/` 中新建（子应用）或 `src/store/modules/` 中新建（micro-main）
3. 定义：初始状态、action（异步）、getter（派生状态）
4. 明确初始化、重置、销毁时机（路由守卫或组件 onUnmounted）

### 容易漏掉的点

- 路由离开时是否需要 `store.$reset()`
- 全局 store 残留上一次状态导致数据串
- 避免 store 与 URL 参数双写（以 URL 为真值，store 只做缓存）

---

## 8. Playbook G：重构组件 / 公共模块

### 重构前必须确认

1. 重构有真实收益（可量化：减少重复代码、解决 bug、提升可测试性）
2. 盘点所有调用方（grep 搜索组件名/函数名）
3. 是否触及 `11_DANGEROUS_AREAS.md` 中的危险区
4. 是否影响 `packages/*` 公共包（需技术方案评审）

### 标准步骤

1. 明确重构范围和非目标（不趁机清理不相关代码）
2. 新建新实现，保留旧实现（不直接改）
3. 逐步迁移调用方（一次一个页面）
4. 确认旧实现无调用方后删除
5. `pnpm run validate` 通过
6. 更新相关 docs

---

## 9. Playbook H：文档更新

满足以下情况时，开发结束后必须同步更新 docs：

- 新增了可复用的 composable / component 模式
- 修改了 API 契约（字段、分页、枚举值）
- 引入了新的危险区或历史坑
- 业务术语或状态流转发生变化
- packages/ 接口或协议发生变化

建议同步更新：

- 对应文档（`03` / `07` / `11` 最常需要更新）
- `00_INDEX.md` 中的初始化状态表（如文档状态变更）

---

## 10. 最后提醒

Playbook 的价值在于减少这些低级损耗：

- 忘记处理空态 / loading / error
- 跳过现有模式直接新造轮子（先找参考再写）
- 动到危险区却没有自检
- Bug 只修症状不修根因
- 接口换了但 mapper / 常量 / 筛选项没一起更新
