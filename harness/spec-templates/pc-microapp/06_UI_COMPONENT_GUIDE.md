# 06_UI_COMPONENT_GUIDE.md

> 🧩 模版骨架（A 精炼版）：保留结构，正文按真实代码填充；拿不准标 `// TODO: 待确认`，禁止编造。

---
owner: Frontend Team
last_verified: <生成时填写>
status: template
purpose: UI 库（dcgj-ui）选型与用法约定
---

## 1. UI 库与选型顺序
<填写：dcgj-ui（基于 ant-design-vue 4）优先；先用现成组件，再用项目封装，最后自写>

## 2. 常用组件清单
<填写：DcgjTable / DcgjFormPro / DcgjDrawer 等，详见 dcgj-components/COMPONENT_INDEX.md>

### 页面类型与设计输入（固定规范）

- 收到 Figma 链接或截图时，先识别目标 Frame/node 与页面类型：列表、新建/编辑或详情；只读取 `examples/` 中对应类型的真实示例，避免无关业务上下文污染实现。
- 依据优先级：当前 Figma 实例确定视觉与状态，PRD 确定字段和业务流程，当前版本组件索引确定可复用能力；示例只提供结构与状态模式，不是字段、尺寸或操作的事实来源。
- 列表页重点核对筛选、工具栏、表格列与行、横向滚动、分页和行操作；新建/编辑页重点核对分区、字段栅格、上传/预览与底部栏；详情页重点核对只读模块、统计/预览、Tab/明细和状态操作。
- 远程选项需要按真实组件能力记录搜索、防抖、分页、去重、loading/empty/error 与已选值回显；列表请求与选项请求的状态彼此独立。
- 视觉验收使用项目 specs 声明的基准、项目声明的最小宽度与宽屏视口；不得从模板硬编码项目专属最小宽度、列数、字段数或组件尺寸。
- 若组件索引确认当前版本已导出对应能力，标准列表优先组合筛选/字段/表格/文本/操作组件；标题化编辑分区与只读详情使用各自组件，不用 disabled 表单模拟详情。

## 3. 主题与全局样式约定
<填写：ConfigProvider / 主题变量入口；不要为局部需求改全局>

### PC 设计 Token

- PC 端色号、字号、边框、背景、控件尺寸等视觉值以 `docs/token-specs/` 为准。
- `docs/token-specs/Light.tokens.json` 是 Figma Light 模式原始 token；`docs/token-specs/antd-vue-theme.ts` 是 Ant Design Vue / dcgj-ui 主题配置参考。
- 实现 Figma 标注的 `Global/Typography/fontSize`、`Global/Colors/*` 等值时，先查 `docs/token-specs/`，不要直接手写新色号或字号。
- 若设计稿出现 token 中不存在的值，标记 `// TODO: 待确认设计 token`，不要自行扩展临时值。

### PC 画布与自适应

- Figma 设计还原以 `1440 × 900` 画布为基准；默认开发与验收视口为 `1920 × 1080`。
- 上述尺寸仅用于视觉对齐与验收，不代表页面固定尺寸；布局应随可用视口自适应。
- 数据密集型页面在窄视口下应保留合理最小宽度并允许横向滚动，优先保证关键操作、表格列和表单控件可用。

## 4. 图标 / 图片素材
<填写：图标与静态资源放置约定>
