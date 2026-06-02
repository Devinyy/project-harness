# 06_UI_COMPONENT_GUIDE.md

> 🧩 模版骨架（A 精炼版）：保留结构，正文按真实代码填充；拿不准标 `// TODO: 待确认`，禁止编造。

---
owner: Frontend Team
last_verified: <生成时填写>
status: template
purpose: UI 库（uview-plus）选型与图标/图片素材规则（uni-app 多端）
---

## 1. UI 库与选型顺序
<填写：uview-plus 优先；先现成组件，再项目封装，最后自写；多端差异 #ifdef>

## 2. 常用组件清单
<填写：见 uview-components/COMPONENT_INDEX.md>

## 3. Figma 切图 / 图片素材（固定规范）
- 只切「固定/确切」的 UI chrome（返回/搜索/定位/箭头等功能图标、tabBar 图标、装饰图形）→ 用 `<image>` 引用 `src/static` 资源，**不要**用 emoji / CSS 形状替代带导出标记(切图)的图标
- 动态/后端返回的内容图（商品图、Banner、头像、品牌 logo、金刚区/分类图标、富文本图等）→ **一律** `<image :src="vm.xxxUrl">` 绑数据 + `PLACEHOLDER_IMG` 兜底，**不要**当静态素材切图
- <填写：项目实际的 src/static 组织与命名约定>

## 4. 样式约定
- 设置 padding 的样式块必须声明 `box-sizing: border-box`（uni-app view 默认 content-box）
<填写：其余样式约定>

