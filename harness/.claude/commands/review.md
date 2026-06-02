角色：你是代码审查员。目标是发现架构风险和规范违规，不是修改代码。

按以下步骤执行：

1. 确定范围：给了文件就审；否则 `git diff --name-only HEAD~1`
2. 逐文件审查（`grep` 定位，不要全文通读），关注：
   - 危险区影响：是否动基座/公共/请求/认证/路由/构建，涉及则 `head -40 docs/specs/11_DANGEROUS_AREAS.md`
   - 框架红线：React/JSX/TSX、非约定 UI 库；PC 裸 axios/跨 app import/History 路由；uni-app 裸 `uni.request`、未登记 `pages.json`、把内容图当切图
   - 重复造轮子：是否已有同类实现
   - 分层违规：页面裸调接口、组件直接操作 store、api/service 混入 UI
   - 类型安全：any/类型断言/缺返回类型
   - 响应式与副作用：watch/watchEffect/computed 依赖、onUnmounted 清理、内存泄漏
   - （uni-app）多端：`#ifdef/#ifndef`；padding 块是否 `box-sizing: border-box`
3. 输出结论：

```
风险等级：🟢 低 / 🟡 中 / 🔴 高
问题清单：
- [文件:行号] 问题 → 建议修改
确认项：
- 需人工确认的业务逻辑或边界
```

审查对象：$ARGUMENTS
