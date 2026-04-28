# 07_API_CONTRACTS.md

---
owner: Frontend Team + Backend Team
last_verified: 2026-04-21
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
  - 09_TECH_SOLUTION_TEMPLATE.md
  - 12_TROUBLESHOOTING.md
---

> 使用说明：
>
> - 本文档回答“接口应该怎么接、字段怎么转、错误怎么处理”
> - 不是完整 OpenAPI 替代品；它强调前端项目中的接入规则和约束
> - 对某个接口的业务含义有争议时，先对齐 `03_BUSINESS_DOMAIN.md`

---

## 1. 目标

通过统一 API 接入规则，解决以下问题：

1. 页面里到处裸调接口
2. 字段转换散落在多个页面
3. 错误码处理不一致
4. null / undefined / 空数组兜底规则不统一
5. 分页、筛选、排序、时间、金额的处理风格不一致
6. 新增的接口代码与项目既有模式不匹配

---

## 2. 单一事实来源

API 信息可能来自多个来源：

- OpenAPI / Swagger
- 后端接口文档
- BFF 文档
- 历史 service 实现
- 联调约定
- PRD / 技术方案

默认优先级建议：

1. 已发布且当前有效的正式接口文档
2. 当前项目中已验证的 service + adapter 实现
3. 经确认的联调说明
4. 历史页面表现

> 历史页面代码只能作为参考，不能天然视为最新契约。

---

## 3. 接口分层

推荐按以下层次组织：

1. `http client`
   - 基础请求能力、超时、鉴权、拦截器、trace 信息
2. `service`
   - 按业务域组织接口，定义请求函数
3. `adapter / mapper`
   - 原始 DTO -> UI Model 的转换
4. `store / query layer`
   - 缓存、共享、请求状态
5. `page / component`
   - 发起动作，消费数据，不处理过多原始协议细节

### 3.1 禁止事项

- 页面内直接拼接完整请求 URL 与 headers
- 多个页面重复手写同一字段转换
- 原始接口数据未经说明直接穿透到各层
- 在 adapter 内夹带 UI 提示或路由跳转

---

## 4. service 组织规则

### 4.1 按领域组织

推荐结构之一：

```text
services/
├── merchant/
│   ├── query.ts
│   ├── mutation.ts
│   ├── adapter.ts
│   ├── types.ts
│   └── mock.ts
├── order/
└── common/
```

或：

```text
services/
├── merchant.service.ts
├── merchant.types.ts
├── merchant.adapter.ts
├── order.service.ts
└── common.service.ts
```

只要保证：

- 领域边界清晰
- 类型、service、适配逻辑能互相找到
- 命名一致

### 4.2 service 函数命名

建议使用动词 + 领域对象：

- `getMerchantList`
- `getMerchantDetail`
- `createMerchant`
- `updateMerchant`
- `toggleMerchantStatus`

不推荐：

- `fetchData`
- `req1`
- `postInfo`
- `getList`（缺少领域语义）

---

## 5. 请求与响应建模

### 5.1 DTO 与 UI Model 分离

推荐明确分为：

- `ApiRequest`
- `ApiResponse`
- `ViewModel` / `DomainModel`

示例：

```ts
export interface MerchantListItemDTO {
  merchant_id: string
  merchant_name: string
  status: 'ENABLED' | 'DISABLED'
  created_at: string | null
}

export interface MerchantListItem {
  merchantId: string
  merchantName: string
  status: 'enabled' | 'disabled'
  createdAt: string
}
```

### 5.2 命名原则

- 接口原始字段保留后端真实结构
- UI 层字段可转为前端统一风格
- 不同层的命名不要混用
- 枚举与状态值的映射关系要有明确位置记录

### 5.3 空值与默认值

请明确：

- `null` 与 `undefined` 的语义区别
- 空数组 vs 无数据 vs 未加载
- 空字符串是否有业务含义
- 数值 0 是否可能与“无值”混淆

---

## 6. adapter / mapper 规则

adapter 负责的内容通常包括：

- 字段重命名
- 时间格式预处理
- 金额 / 分位值转换
- 枚举值映射
- 补默认值
- 兼容后端脏数据

不应负责：

- UI 提示
- 组件状态切换
- 路由跳转
- 权限判断

### 6.1 建议写法

```ts
export function adaptMerchantListItem(dto: MerchantListItemDTO): MerchantListItem {
  return {
    merchantId: dto.merchant_id,
    merchantName: dto.merchant_name ?? '-',
    status: dto.status === 'ENABLED' ? 'enabled' : 'disabled',
    createdAt: dto.created_at ?? '',
  }
}
```

### 6.2 何时不需要 adapter

如果后端字段和前端展示模型已经稳定统一，可不强制拆 adapter，但要满足：

- 字段语义清晰
- 页面不重复写转换
- 将来需要适配时有合理接入点

---

## 7. 错误处理与错误码

### 7.1 错误类型

建议区分：

- 网络错误
- 认证错误（401）
- 权限错误（403）
- 资源不存在（404）
- 参数校验错误（4xx）
- 业务错误码
- 服务异常（5xx）

### 7.2 错误处理职责

- `http client`：统一处理网络级错误、超时、重试、鉴权
- `service`：识别接口级失败结构
- `page / feature`：决定用户提示与恢复动作
- `global monitor`：上报异常上下文

### 7.3 错误提示原则

- 用户能处理的错误，要给可行动的提示
- 无权限、无数据、接口失败、系统异常应区别对待
- 不要把后端原始报错直接原样展示给用户，除非经过确认适合外露

### 7.4 业务错误码表

建议维护一份高频业务错误码说明，例如：

- `MERCHANT_NOT_FOUND`
- `STATUS_NOT_EDITABLE`
- `INVALID_DATE_RANGE`
- `EXPORT_TASK_LIMIT_EXCEEDED`

可写明：

- 错误码
- 含义
- 常见触发场景
- 前端提示或处理方式

---

## 8. 分页、筛选、排序、搜索

### 8.1 分页协议

明确：

- 当前页参数名
- 每页条数参数名
- 返回总数字段名
- 是否从 0 开始还是从 1 开始
- 删除当前页最后一条后的回退策略

### 8.2 筛选协议

明确：

- 空筛选条件如何表示
- 多选条件如何传递
- 日期范围如何传递
- 枚举值与展示值如何对应
- 是否支持保留 URL 参数

### 8.3 排序协议

明确：

- 排序字段名
- 顺序字段名
- 支持单列还是多列
- 未指定排序时默认值是什么

---

## 9. 时间、金额、数值精度规则

这些最容易出现隐藏 bug，建议单独说明。

### 9.1 时间

请明确：

- 接口返回的是时间戳、ISO 字符串还是本地时间文本
- 展示层是否统一转换时区
- 提交时是否需要转 UTC
- 日期区间的起止边界如何处理

### 9.2 金额

请明确：

- 接口返回单位：元 / 分 / 厘
- 展示层是否保留两位小数
- 输入时如何校验
- 精度处理在哪里做

### 9.3 百分比 / 率值

请明确：

- 接口是 0.15 还是 15
- 展示时是否追加 `%`
- 输入组件与接口值如何映射

---

## 10. 枚举、状态与字典

建议统一记录：

- 后端枚举值
- 前端内部值
- 展示文案
- Tag 颜色 / 图标
- 可执行操作

不要在多个页面重复写：

```ts
status === 'ENABLED' ? '启用中' : '停用中'
```

而应集中到：

- 常量文件
- adapter
- status helper
- 统一展示组件

---

## 11. 鉴权、上下文与拦截器

说明：

- Token 从哪里取
- 过期如何处理
- 多租户 / 站点 / locale / trace 信息如何注入
- 下载、上传接口是否需要特殊处理
- 某些接口是否需要跳过统一拦截

> 修改这些逻辑时，务必同步查看 `11_DANGEROUS_AREAS.md`。

---

## 12. 缓存、重试、取消、并发

明确：

- 哪些请求允许缓存
- 哪些操作成功后需要主动失效缓存
- 是否自动重试，重试几次
- 搜索输入是否做防抖
- 路由切换或组件销毁时是否取消请求
- 并发请求结果冲突时以谁为准

---

## 13. 文件上传 / 下载

对上传、导出、异步下载类接口，建议单列规则：

- 文件大小限制
- 文件类型限制
- 上传进度展示
- 上传失败回退策略
- 导出是否同步 / 异步任务
- 下载链接时效
- 前端轮询还是后端回调

---

## 14. Mock 与联调策略

请明确：

- 本地 Mock 如何开启
- Mock 文件放哪里
- Mock 数据命名规则
- 联调前后如何切换
- 临时 Mock 是否允许提交到主干
- 是否需要保留契约测试或 fixture

---

## 15. 单接口说明模板

对关键接口，建议按以下格式记录：

```md
### GET /api/merchants

- 作用：查询商家列表
- 调用方：商家列表页
- 请求参数：
  - `page`: 页码，从 1 开始
  - `pageSize`: 每页条数
  - `keyword`: 商家名称关键字
  - `status`: 商家状态
- 响应结构：
  - `list`: 商家列表
  - `total`: 总数
- 字段映射：
  - `merchant_id` -> `merchantId`
  - `merchant_name` -> `merchantName`
- 失败处理：
  - 401：跳登录 / 刷新凭证
  - 403：显示无权限
  - 业务错误：toast + 保持筛选条件
- 备注：
  - 删除当前页最后一条后需要回退一页
```

---

## 16. 变更管理

当接口契约变化时，建议记录：

- 变化内容
- 影响页面
- 影响字段
- 是否兼容旧版本
- 回归重点
- 谁负责同步前端 / 后端 / QA

对高影响变更，建议同步补充：

- 技术方案
- 发布计划
- 回滚策略
- `12_TROUBLESHOOTING.md` 的新增排障项

---

## 17. 注意事项

接入接口时，应注意：

- 先找现有 service 与同领域 adapter
- 优先沿用既有命名与文件结构
- 不在页面中裸写原始接口协议
- 对不确定的字段含义列出待确认项
- 显式处理错误、空值、加载与刷新时机
- 涉及鉴权、拦截器、全局 client 修改时先看 `11_DANGEROUS_AREAS.md`
