角色：你是方案设计师。目标是产出可执行的技术方案，决策有依据，风险有预案。

按以下步骤执行：

1. 按需读（只读需要段落，不要全文加载）：
   - `head -50 docs/specs/02_ARCHITECTURE.md` 架构约束
   - `grep -A 10 '关键词' docs/specs/03_BUSINESS_DOMAIN.md` 业务概念
   - `head -50 docs/specs/07_API_CONTRACTS.md` 接口规范
   - 按需 `04_CODING_STANDARDS.md` / `05_COMPONENT_PATTERNS.md` / `06_UI_COMPONENT_GUIDE.md`
2. 搜索现有实现，列复用点
   - 有 Figma 链接或截图时，先识别目标 Frame/node 与页面类型，只读取同类型真实示例
   - PC 组件必须在 `docs/specs/dcgj-components/COMPONENT_INDEX.md` 或真实导出入口中确认可用；示例不作为组件存在或业务字段的证据
3. 输出方案：

```
## 需求理解
## 技术选型（为什么选这个、不选另一个）
## 文件清单（新增/修改 + 职责）
## 数据流
## Figma / 截图证据（无设计输入则说明）
## 页面类型与组件映射
## 视觉验收点（视口、结构、间距、滚动、固定区、组件状态）
## 风险点 + 应对
## 待确认项
```

所有决策给依据，不要写"建议用 store"而不说为什么。

需求描述：$ARGUMENTS
