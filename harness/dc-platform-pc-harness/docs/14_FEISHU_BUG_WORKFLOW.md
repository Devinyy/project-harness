# 飞书 Bug 表读取与修复标准流程

## 1. 认证授权

首次使用需完成飞书 OAuth 授权：

```bash
lark-cli auth login --domain wiki
```

浏览器打开返回的链接完成授权，确认 scopes 包含 `wiki:node:read`、`bitable:record:read` 等。

检查当前授权状态：

```bash
lark-cli auth status
```

## 2. 解析 Wiki 链接

从飞书 Wiki 页面中的多维表格获取 Base 信息：

```bash
lark-cli wiki spaces get_node --token <wiki_token>
```

返回结果中的 `obj_token` 即为 Base 的 `app_token`，`obj_type` 确认是否为 `bitable`。

> **输入格式**：从 URL `https://xxx.feishu.cn/wiki/<wiki_token>?table=<table_id>&view=<view_id>` 中提取各参数。

## 3. 获取表结构

### 3.1 列出所有数据表

```bash
lark-cli base +table-list --base-token <app_token>
```

确认目标表的 `table_id` 和名称。

### 3.2 列出字段结构

```bash
lark-cli base +field-list --base-token <app_token> --table-id <table_id>
```

记录关键字段的 `field_id`、`field_name`、`type`，用于后续筛选条件构造。

## 4. 筛选记录

使用 `+record-search` 按条件筛选，需指定 `search_fields`：

```bash
lark-cli base +record-search \
  --base-token <app_token> \
  --table-id <table_id> \
  --json '{
    "keyword": "<搜索关键词>",
    "search_fields": ["<字段名>"],
    "filter": {
      "conjunction": "and",
      "conditions": [
        {
          "field_name": "<字段名>",
          "operator": "is",
          "value": ["<匹配值>"]
        },
        {
          "field_name": "<字段名>",
          "operator": "isNot",
          "value": ["<排除值1>", "<排除值2>"]
        }
      ]
    }
  }'
```

### 筛选条件说明

| operator | 含义 | 注意事项 |
|----------|------|----------|
| `is` | 等于 | 单选/多选字段用选项名称匹配 |
| `isNot` | 不等于 | 多个 value 之间是 OR 关系（排除任一匹配） |
| `contains` | 包含 | 不支持日期字段 |
| `isEmpty` | 为空 | 不需要 value |
| `isNotEmpty` | 不为空 | 不需要 value |

### 常见问题

- **`search_fields` 必填**：`+record-search` 必须指定搜索字段数组，否则报错
- **选项名称精确匹配**：筛选条件中的 value 必须与表中选项名称完全一致（含空格），如 `"不是 Bug"` 而非 `"不是Bug"`
- **人员字段**：需使用 `open_id` 而非姓名匹配

## 5. 分析与修复

从筛选结果中提取 Bug 详情：

1. **读取记录字段**：关注标题、描述、优先级、截图等
2. **定位代码**：根据描述在代码库中找到相关文件
3. **逐个修复**：每个 Bug 独立分支或提交
4. **验证**：本地运行确认修复效果

## 6. 完整示例

```bash
# 1. 认证
lark-cli auth login --domain wiki

# 2. 解析 wiki 链接
lark-cli wiki spaces get_node --token LVtEwqJy4iCZAdkw9vrcWm1pnZg

# 3. 查看表结构
lark-cli base +table-list --base-token <app_token>
lark-cli base +field-list --base-token <app_token> --table-id <table_id>

# 4. 筛选未关闭的 Bug
lark-cli base +record-search \
  --base-token <app_token> \
  --table-id <table_id> \
  --json '{
    "keyword": "张翔",
    "search_fields": ["指派人"],
    "filter": {
      "conjunction": "and",
      "conditions": [
        {"field_name": "迭代版本", "operator": "is", "value": ["运营管理后台-商品商家管理后台-PC-商品"]},
        {"field_name": "状态", "operator": "isNot", "value": ["已关闭", "不是 Bug", "待验收", "拒绝"]}
      ]
    }
  }'

# 5. 查看详情
lark-cli base +record-get --base-token <app_token> --table-id <table_id> --record-id <record_id>
```
