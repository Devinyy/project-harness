# PC 端设计 Token 说明

本目录存放 PC 端设计 token，后续 PC 微前端页面的颜色、字号、边框、背景、控件尺寸等视觉值，以这里为准。

## 文件

- `Light.tokens.json`：Figma 导出的 Light 模式原始 token，作为设计源数据。
- `antd-vue-theme.ts`：从 Figma token 派生出的 Ant Design Vue / dcgj-ui 主题配置，可用于 `ConfigProvider` token 对齐。

## 使用规则

1. 新增或调整 PC 页面样式时，优先从 `Light.tokens.json` 或 `antd-vue-theme.ts` 查找对应 token，不直接手写新色号或字号。
2. 需要覆盖 dcgj-ui / Ant Design Vue 组件样式时，优先匹配 `antd-vue-theme.ts` 中的 token 名称和值。
3. Figma 标注为 `Global/Typography/fontSize`、`Global/Colors/*` 等 token 时，以 `Light.tokens.json` 中同名层级为准。
4. 如果设计稿使用了 token 中不存在的值，先标记 `TODO: 待确认设计 token`，不要自行扩展临时色号或字号。
5. 页面局部 CSS 变量可以使用业务前缀封装，但变量值必须来自本目录 token。

## 更新方式

设计侧重新导出 token 后，原样替换本目录对应文件，并在涉及页面中同步校验色号、字号与组件主题是否仍一致。
