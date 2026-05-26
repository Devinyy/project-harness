# AGENTS.md — src/components/

本目录存放业务组件（非基础 UI 组件）。

## 规则

- 新建组件前先搜索是否已有同类实现
- 组件文件夹结构：`ComponentName/index.tsx` + `ComponentName/types.ts`
- Props 类型必须显式定义，不用 `any`
- 每个组件有明确的「负责」和「不负责」边界
- 不要把局部特例硬塞进已有组件，新建一个
- 不要在组件内直接调用 API，通过 props 或 hook 传入数据
