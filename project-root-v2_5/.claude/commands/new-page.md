你的任务是新增一个页面。按以下步骤执行：

1. 先 `cat docs/specs/02_ARCHITECTURE.md` 确认目录结构和路由组织方式
2. 在项目中搜索同类页面（`find src/pages -name "*.tsx" | head -10`），找到最相似的现有页面作为骨架参考
3. 确认该页面需要的：
   - 路由路径
   - 数据来源（哪些 service/API）
   - 状态管理方式（local state / store）
   - 权限要求
4. 按现有页面风格创建文件，覆盖以下态：loading / empty / error / 正常渲染
5. 如果需要新 service，在现有 service 目录中创建，遵循现有命名和组织方式
6. 完成后运行 CLAUDE.md 中声明的类型检查命令确认类型正确

需求描述：$ARGUMENTS
