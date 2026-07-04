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

## 3. 主题与全局样式约定
<填写：ConfigProvider / 主题变量入口；不要为局部需求改全局>

### PC 设计 Token

- PC 端色号、字号、边框、背景、控件尺寸等视觉值以 `docs/token-specs/` 为准。
- `docs/token-specs/Light.tokens.json` 是 Figma Light 模式原始 token；`docs/token-specs/antd-vue-theme.ts` 是 Ant Design Vue / dcgj-ui 主题配置参考。
- 实现 Figma 标注的 `Global/Typography/fontSize`、`Global/Colors/*` 等值时，先查 `docs/token-specs/`，不要直接手写新色号或字号。
- 若设计稿出现 token 中不存在的值，标记 `// TODO: 待确认设计 token`，不要自行扩展临时值。

## 4. 图标 / 图片素材
<填写：图标与静态资源放置约定>
