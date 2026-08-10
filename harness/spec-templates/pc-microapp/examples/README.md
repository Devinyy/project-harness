# examples/（模版骨架）

放"填得好"的示例（技术方案/API 契约/任务拆解/业务术语/组件模式 Vue SFC）。可留空或放 1~2 个真实示例。不要把示例业务当真实规则。

## Figma / 截图驱动的页面示例

项目存在可验证的真实页面时，按页面类型组织；没有对应真实页面时不要为了凑齐目录编造示例：

```text
EXAMPLE_<DOMAIN>_OVERVIEW.md   # 只做页面特征与示例路由
EXAMPLE_<DOMAIN>_LIST_PC.md    # 筛选、工具栏、表格、分页、行操作
EXAMPLE_<DOMAIN>_FORM_PC.md    # 新建/编辑分区、字段、上传/预览、底部栏
EXAMPLE_<DOMAIN>_DETAIL_PC.md  # 只读模块、统计/预览、Tab/明细、状态操作
```

收到设计输入后，先在 OVERVIEW 中按 Frame/截图特征选择同类型示例，再以 Figma 与 PRD 覆盖示例中的字段、尺寸和操作。每份示例明确“可复用模式”和“不可泛化的业务事实”。
