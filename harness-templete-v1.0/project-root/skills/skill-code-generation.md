# Skill 2: 编写代码 + 测试用例

> 文件位置：`skills/skill-code-generation/SKILL.md`

---

## 触发条件

当 agent 收到已定稿的技术方案，或收到不需要先出方案的简单任务时，执行本 skill。

---

## 输入

| 输入项 | 来源 | 必需 |
|-------|------|------|
| 技术方案文档 | skill-1 输出 或 用户提供 | 是（复杂需求） |
| 需求描述 | 用户提供 | 是（简单需求） |
| `docs/02_ARCHITECTURE.md` | 项目 docs/ | 是 |
| `docs/04_CODING_STANDARDS.md` | 项目 docs/ | 是 |
| `docs/05_COMPONENT_PATTERNS.md` | 项目 docs/ | 是 |
| `docs/06_UI_COMPONENT_GUIDE.md` | 项目 docs/ | 是 |
| `docs/07_API_CONTRACTS.md` | 项目 docs/ | 是 |
| `docs/08_TASK_PLAYBOOKS.md` | 项目 docs/ | 是 |
| `docs/11_DANGEROUS_AREAS.md` | 项目 docs/ | 条件触发 |
| `docs/examples/EXAMPLE_COMPONENT_PATTERN.md` | 参考示例 | 推荐 |

---

## 执行步骤

### Step 1: 开发前分析

输出开发前摘要：

```
- 任务目标：
- 参考文档：
- 复用点：（列出复用的页面、组件、hook、service）
- 改动点：（列出新增和修改的文件）
- 风险点：
- 自测点：
```

### Step 2: 选择 Playbook

根据任务类型，从 `docs/08_TASK_PLAYBOOKS.md` 选择对应 playbook：

| 任务类型 | Playbook |
|---------|----------|
| 新增列表页 | A |
| 新增详情页 | B |
| 新增表单 | C |
| 接入新接口 | D |
| 新增 store | E |
| 新增权限/路由 | F |
| 修复 Bug | G |
| 重构 | H |

### Step 3: 编写代码

按 playbook 步骤和技术方案逐步实现，遵守以下规则：

**文件组织**
- 根据 `docs/02` 判断每个文件的归属层级
- 根据 `docs/05` 决定组件目录结构（单文件 vs 文件夹）
- 参考 `docs/examples/EXAMPLE_COMPONENT_PATTERN.md` 的分层方式

**类型定义**
- DTO 与 ViewModel 分离（参考 `docs/07`）
- Props 类型显式定义
- 枚举和常量集中管理

**组件实现**
- 遵循 `docs/04` 的编码规范
- 遵循 `docs/06` 的 UI 选型规则
- 每个组件有明确的"职责"和"不负责"边界

**Service / Hook**
- Service 按领域组织（参考 `docs/07`）
- Hook 职责单一，输入输出类型明确
- Adapter 集中处理字段转换

**状态管理**
- 按技术方案中的状态归属决策实现
- 不擅自提升状态到全局

**错误处理 / 反馈态**
- 显式处理 loading / empty / error / 权限不足
- 提交操作有防重复保护
- 成功后有明确的刷新或跳转策略

### Step 4: 编写测试用例

根据技术方案中的验收标准和自测清单，生成测试用例：

**单元测试**
- adapter / mapper 的转换逻辑
- 工具函数
- 关键 hook 的输入输出

**组件测试**
- 正常渲染
- 交互行为（点击、输入、提交）
- 边界态（空数据、错误、loading）
- 权限控制（按钮显隐、字段可编辑性）

**集成测试要点**（供手动验证或 E2E）
- 完整用户流程
- 不同角色场景
- 异常路径

### Step 5: 自检

按 `agent.md` 第 6.3 节的自检清单逐项检查：

- [ ] 命名符合项目规范
- [ ] 类型完整，无遗漏 any
- [ ] 错误处理显式
- [ ] 空态 / loading / error 覆盖
- [ ] 权限判断到位
- [ ] 不违反 `docs/11` 中的红线
- [ ] 不违反 `docs/06` 中的反模式

---

## 输出

- 代码文件（按技术方案的文件清单组织）
- 测试用例文件
- 开发后摘要：

```
- 实际修改文件：
- 与技术方案的差异：
- 遗留待确认项：
- 推荐回归路径：
- 是否需要更新 docs：
```

---

## 质量标准

- 代码结构与技术方案一致
- 遵循项目现有风格，不引入新的命名或组织方式
- 所有组件覆盖 loading / empty / error 反馈态
- service 层与页面层职责分离
- 测试用例覆盖正常路径 + 关键边界
- 无未处理的待确认项被默认实现
