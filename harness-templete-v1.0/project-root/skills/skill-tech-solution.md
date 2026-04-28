# Skill 1: 生成技术方案

> 文件位置：`skills/skill-tech-solution/SKILL.md`

---

## 触发条件

当 agent 收到 PRD / 需求描述，且满足以下任一条件时，执行本 skill：

- 新增页面或完整模块
- 同时影响 route / page / feature / service / store
- 涉及复杂状态流转
- 业务规则多且边界复杂
- 重构公共区域

> 判断标准详见 `docs/10_TECH_SOLUTION_PLAYBOOK.md` 第 2 节。

---

## 输入

| 输入项 | 来源 | 必需 |
|-------|------|------|
| PRD / 需求描述 | 用户提供 | 是 |
| 设计稿链接 | 用户提供 | 否 |
| `docs/01_PROJECT_OVERVIEW.md` | 项目 docs/ | 是 |
| `docs/02_ARCHITECTURE.md` | 项目 docs/ | 是 |
| `docs/03_BUSINESS_DOMAIN.md` | 项目 docs/ | 是 |
| `docs/06_UI_COMPONENT_GUIDE.md` | 项目 docs/ | 是 |
| `docs/07_API_CONTRACTS.md` | 项目 docs/ | 是 |
| `docs/11_DANGEROUS_AREAS.md` | 项目 docs/ | 是 |
| `docs/09_TECH_SOLUTION_TEMPLATE.md` | 模板 | 是 |
| `docs/10_TECH_SOLUTION_PLAYBOOK.md` | 流程指南 | 是 |
| `docs/examples/EXAMPLE_FILLED_TECH_SOLUTION.md` | 参考示例 | 推荐 |

---

## 执行步骤

### Step 1: 理解需求

- 阅读 PRD，提取用户目标、核心流程、角色差异
- 对照 `docs/03` 确认术语和业务规则
- 列出不清楚的点作为待确认项

### Step 2: 确定范围

- 明确本次做什么、不做什么
- 识别影响的页面、组件、service、store、路由、权限、埋点
- 参考 `docs/02` 判断改动归属哪一层

### Step 3: 调研现有实现

- 在项目代码中查找同类页面、组件、service
- 列出可直接复用、需要扩展、必须新增的部分
- 参考 `docs/05` 和 `docs/06` 确认组件模式和 UI 选型

### Step 4: 设计方案

按 `docs/09_TECH_SOLUTION_TEMPLATE.md` 的结构逐节填写：

1. 背景与目标
2. 需求范围
3. 用户流程与页面影响面
4. 现状调研
5. 信息架构与路由设计
6. UI 与组件方案
7. 数据流设计
8. API 与字段映射
9. 状态管理方案
10. 权限、埋点、国际化
11. 风险点与兼容性评估
12. 实现拆分
13. 验收标准
14. 待确认问题

### Step 5: 自检

按 `docs/10` 第 9 节的自检清单逐项检查：

- 范围是否清楚
- 复用判断是否充分
- 数据流是否合理
- UI 方案是否合理
- 风险是否识别充分
- 方案是否能直接指导开发

---

## 输出

- 一份完整的技术方案文档（Markdown）
- 待确认问题列表
- 预计改动文件清单

---

## 质量标准

- 所有决策有依据，不出现无理由的"建议"
- 不确定项明确标记，不伪确定
- 不包含超出需求范围的重构或基础设施改造
- 边界场景（空态、loading、error、权限、重复提交）全部覆盖
- 开发者拿到方案后能明确知道改哪些层、先做什么、有哪些风险
