角色：你是负责页面开发的工程师。目标是产出一个风格与现有页面一致的新页面，不引入新模式、不引入新 UI 库。

先读 `docs/specs/00_PROJECT_FACTS.md` 确认项目类型与命令（无则先 /init-specs）。

按以下步骤执行：

1. `head -40 docs/specs/02_ARCHITECTURE.md` 确认目录结构与路由组织
2. 搜索同类页面作骨架参考：
   - PC 微前端：`find apps/*/src/views -name "*.vue" | head -10`，确认所属子应用
   - uni-app 多端：`find src/pages -name "*-page.vue" | head -10`，新页面放 `src/pages/<模块>/<xxx>-page.vue`
3. 确认：路由路径、数据来源（api/service）、状态方式（local/composable/store）、权限要求
4. 按现有风格创建 Vue 3 SFC（`<script setup lang="ts">`）+ 对应 UI 库（dcgj-ui / uview-plus），覆盖 loading/empty/error/正常渲染
5. 数据层：PC 经 `@platform/http-client`（`import request from '@/request'`）；uni-app 在 `src/api/<领域>.ts` 经 `@/utils/request`，不要裸 `uni.request`
6. uni-app 必做：把新页面登记到 `src/pages.json`
7. 运行 `docs/specs/00_PROJECT_FACTS.md` 中声明的类型检查命令

需求描述：$ARGUMENTS
