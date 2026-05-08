# DcgjPayment 插件式支付流程引擎

## 何时使用

当你需要实现一个多步骤的支付流程（如选择支付方式 → 确认订单 → 输入密码 → 完成支付），且每个步骤由独立的插件组件驱动时，使用此组件。它提供了完整的流程控制（步骤跳转、跳过、依赖）、金额管理（折扣/费用）、事件系统和插件生命周期钩子。如果你只需要一个简单的支付弹窗，不需要此组件。

## 基于

独立组件，非 antd 二次封装。

## 相比原生 antd 的差异

- ✅ 新增：插件式架构，每个支付步骤由独立的 Vue 组件（插件）驱动
- ✅ 新增：完整的流程控制——步骤依赖、跳过、跳转、自动跳过已完成步骤
- ✅ 新增：金额服务——支持注册折扣和费用，自动计算最终金额
- ✅ 新增：14 个插件生命周期钩子（`onInit`、`validate`、`execute`、`onError` 等）
- ✅ 新增：7 个 Composable Hooks 供插件组件内部使用
- ✅ 新增：事件系统支持 9 种事件类型
- ✅ 新增：`PaymentProvider` 支持嵌套复用同一个 Core 实例

## Props

| Prop | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `amount` | `Number` | **是** | — | 支付金额 |
| `config` | `PaymentFlowConfig` | **是** | — | 流程配置（步骤 + 插件） |
| `businessData` | `BusinessData` | 否 | `{}` | 业务数据（可在插件间共享） |
| `runPlugin` | `Boolean` | 否 | `true` | 是否自动运行当前步骤的插件 |
| `completedSteps` | `string[]` | 否 | `[]` | 已完成的步骤 ID 列表 |
| `autoSkipCompletedSteps` | `Boolean` | 否 | `false` | 是否自动跳过已完成步骤 |

### PaymentFlowConfig 类型

```ts
interface PaymentFlowConfig {
  steps: PaymentStep[];
  plugins: Record<string, PaymentPlugin>;
}

interface PaymentStep {
  id: string;
  pluginId: string;
  config: {
    required?: boolean;
    enabled?: boolean;
    skip?: boolean;
    [key: string]: any;
  };
  dependsOn?: string[];  // 依赖的步骤 ID
}

interface PaymentPlugin {
  id: string;
  name: string;
  component: any;  // Vue 组件
}
```

## Events

| Event | Params | Description |
|-------|--------|-------------|
| `statusChange` | `PaymentStatus` | 支付状态变更（`PENDING`/`PARTIAL`/`COMPLETED`/`ERROR`） |
| `stepChange` | `string` | 当前步骤变更，参数为 stepId |
| `complete` | 无 | 支付流程完成 |
| `error` | `Error` | 流程出错 |
| `stepComplete` | `FlowStepCompleteEvent` | 单个步骤完成 |

## Slots

| Slot | Scope Props | Description |
|------|-------------|-------------|
| `default` | 无 | 默认插槽，始终渲染（可用于展示完成状态等） |

> 插件组件通过 `h()` 动态渲染，不通过插槽传入。

## Expose

| Method/Property | Type | Description |
|-----------------|------|-------------|
| `core` | `Ref<PaymentCore>` | 响应式的支付核心实例 |
| `startPayment` | `(options?) => Promise<void>` | 启动支付流程。可传 `{ skipMarkedSteps: true }` 跳过标记步骤 |

## 使用示例

```vue
<!-- 示例 1：基础用法 -->
<template>
  <DcgjPayment
    :amount="9900"
    :config="paymentConfig"
    :business-data="{ orderId: 'ORD001' }"
    @status-change="handleStatusChange"
    @complete="handleComplete"
  >
    <div v-if="isCompleted">支付完成！</div>
  </DcgjPayment>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { DcgjPayment } from '@/components';
import type { PaymentFlowConfig, PaymentStatus } from '@/components';
import PayMethodPlugin from './plugins/PayMethodPlugin.vue';
import PasswordPlugin from './plugins/PasswordPlugin.vue';

const isCompleted = ref(false);

const paymentConfig: PaymentFlowConfig = {
  steps: [
    { id: 'select', pluginId: 'payMethod', config: { required: true, enabled: true } },
    { id: 'password', pluginId: 'passwordInput', config: { required: true, enabled: true }, dependsOn: ['select'] },
  ],
  plugins: {
    payMethod: { id: 'payMethod', name: '选择支付方式', component: PayMethodPlugin },
    passwordInput: { id: 'passwordInput', name: '输入密码', component: PasswordPlugin },
  },
};

const handleStatusChange = (status: PaymentStatus) => {
  console.log('状态变更:', status);
};

const handleComplete = () => {
  isCompleted.value = true;
};
</script>
```

```vue
<!-- 示例 2：在插件组件中使用 Composable Hooks -->
<script setup lang="ts">
// plugins/PayMethodPlugin.vue
import { usePluginFlow, usePaymentStatus, usePluginAmount, usePaymentBusiness } from '@/components';

const { completeStep, getCurrentStepIndex, getTotalSteps } = usePluginFlow();
const { status, isPending } = usePaymentStatus();
const { amount, amountBreakdown, applyDiscount } = usePluginAmount();
const { getBusinessData } = usePaymentBusiness();

const handleSelect = async (method: string) => {
  // 应用折扣
  applyDiscount('coupon', 500);
  // 获取业务数据
  const orderId = getBusinessData<string>('orderId');
  console.log('订单:', orderId, '金额:', amount.value);
  // 完成当前步骤
  await completeStep();
};
</script>
```

## 注意事项

1. **Composable Hooks**：以下 7 个 Hooks 仅在插件组件内部（即在 `DcgjPayment` 或 `PaymentProvider` 的子组件中）可用：
   - `usePaymentCore()` — 获取 PaymentCore 实例
   - `usePaymentPlugin()` — 获取当前步骤和插件信息
   - `usePaymentStatus()` — 获取支付状态
   - `usePaymentEvents()` — 订阅事件
   - `usePaymentBusiness()` — 读写业务数据
   - `usePluginFlow()` — 流程控制（完成步骤、跳转、跳过等）
   - `usePluginAmount()` — 金额管理（折扣、费用）
2. **嵌套 Provider**：`PaymentProvider` 支持嵌套使用，内层会自动复用外层的 Core 实例。
3. **步骤依赖**：`dependsOn` 中的步骤必须完成后，当前步骤才能开始。
4. **插件生命周期**：插件组件可实现 `PluginLifecycle` 接口的 14 个钩子方法，在 `PaymentCore` 中自动调用。
5. **PaymentStatus 枚举**：`PENDING`（待处理）、`PARTIAL`（部分完成）、`COMPLETED`（已完成）、`ERROR`（出错）。
