# EXAMPLE_API_CONTRACT_ENTRY.md

> 说明：这是 `07_API_CONTRACTS.md` 中“单接口说明模板”的已填充示例。

---
owner: Frontend Team
last_verified: 2026-04-21
status: example
purpose: 演示接口契约文档该如何记录请求、字段映射、错误处理和刷新策略。
related:
  - ../07_API_CONTRACTS.md
---

## GET /api/merchants

- 作用：查询商家列表
- 调用方：
  - 商家列表页首屏加载
  - 商家筛选条件变化后刷新
  - 批量操作成功后刷新
- 请求方式：`GET`

### 请求参数

- `page: number`
  - 页码，从 1 开始
- `pageSize: number`
  - 每页条数
- `keyword?: string`
  - 商家名称关键字
- `status?: ENABLED | DISABLED`
  - 商家状态
- `merchantType?: string`
  - 商家类型
- `createdStart?: string`
  - 创建时间起始
- `createdEnd?: string`
  - 创建时间结束

### 响应结构（原始 DTO）

```json
{
  "list": [
    {
      "merchant_id": "m_1001",
      "merchant_name": "示例商家",
      "merchant_type": "CHAIN",
      "status": "ENABLED",
      "created_at": "2026-04-01T10:00:00Z"
    }
  ],
  "total": 128
}
```

### 前端展示模型

```ts
interface MerchantListItem {
  merchantId: string
  merchantName: string
  merchantType: string
  status: 'enabled' | 'disabled'
  createdAt: string
}
```

### 字段映射

- `merchant_id` -> `merchantId`
- `merchant_name` -> `merchantName`
- `merchant_type` -> `merchantType`
- `status: ENABLED` -> `status: enabled`
- `status: DISABLED` -> `status: disabled`
- `created_at` -> `createdAt`

### 错误处理

- 401：按全局逻辑处理登录态失效
- 403：页面显示无权限或空白权限态
- 404：不适用
- 5xx：列表区显示重试态，保留筛选条件
- 业务错误：toast 提示后不清空筛选项

### 刷新策略

以下场景需要刷新本接口：

- 修改商家状态成功
- 批量操作成功
- 新建商家成功并返回列表
- 重置筛选条件

### 备注

- 删除当前页最后一条后，需要回退到上一页再刷新
- 若 keyword 为空字符串，应在请求层清洗为不传
