# 示範：ui-contract.md（訂單退款 · Nuxt 4 · TypeScript strict）

> 完整成品示範，呼應 screens/example-screen-map.md、後端 gherkin 訂單退款。
> 實際產出寫到 `specs/<slug>/ui_contract/ui-contract.md`。本例假設 `api/openapi.yaml` 已存在（消費它）。
> 前端棧 Nuxt 4：元件規劃在本契約內（**前端無 component_design 階段、不畫 class diagram**）；型別禁 any，見 `../../pm-to-eng-flow/references/frontend-stack-conventions.md`。

## 來源

- `screens/screen-map.md`（畫面 + 扁平元件清單 + 互動）
- `design/`（設計師 Claude Design HTML，若有 → 對照版面決定要規劃哪些元件）
- `api/openapi.yaml`（資料 / 端點單一事實來源）
- `clarify/clarified.md`（範例資料 → fixtures）

## 0. 承載元件 / composable 規劃（取代 component_design · 輕量夠用）

| 元件 / composable | 角色 | typed props / emits / 回傳 |
|---|---|---|
| `OrderDetailPage`（`pages/orders/[id].vue`） | 容器 | 取 route `id`；用 `useOrder(id)` |
| `useOrder(id: string)` | composable | 回 `{ order: Ref<Order \| null>; pending: Ref<boolean>; refresh: () => Promise<void> }`（內用 `useFetch<Order>`） |
| `OrderInfoCard` | 展示 | `defineProps<{ order: Order; canRefund: boolean }>()`；`defineEmits<{ requestRefund: [] }>()` |
| `RefundDialog` | 展示 | `defineProps<{ open: boolean; orderAmount: number }>()`；`defineEmits<{ submit: [amount: number]; cancel: [] }>()`；`useRefund()` |
| `useRefund(id: string)` | composable | 回 `{ amount: Ref<number>; error: Ref<string \| null>; canSubmit: ComputedRef<boolean>; submit: () => Promise<void> }` |

---

## 1. View Model

### 訂單詳情 `/orders/:id`（容器 `OrderDetailPage` + `useOrder`）

| 欄位 | 顯示/送出 | 來源 | 對應元件 |
|---|---|---|---|
| `order.id` | 顯示 | `readOrder` → `Order.id` | OrderInfoCard |
| `order.amount` | 顯示 | `readOrder` → `Order.amount` | OrderInfoCard |
| `order.status` | 顯示 | `readOrder` → `Order.status` | 狀態標籤 |
| `canRefund` | 顯示（控制按鈕） | 衍生：`status==='已付款' && isStaff` | OrderInfoCard.props.canRefund |
| `refundAmount` | 送出 | `orderApplyRefund` body `amount` | RefundDialog.state.amount |

## 2. 互動 → 事件 → 動作

| 畫面 | 互動 | 事件（`defineEmits<T>()`） | 動作 | 結果 |
|---|---|---|---|---|
| 列表 | 點訂單 | `selectOrder: [id: string]` | `navigateTo('/orders/' + id)` | 導詳情 |
| 詳情 | 申請退款 | `requestRefund: []` | `dialogOpen.value = true` | 開 modal |
| 退款框 | 確認 | `submit: [amount: number]` | `useRefund().submit()` → `applyRefund(id, amount)` | 成功：關 modal + `useOrder().refresh()`；失敗：顯錯 |
| 退款框 | 取消 | `cancel: []` | `dialogOpen.value = false` | 關 modal |

### 失敗分支對應後端錯誤碼

| 動作 | 錯誤碼 (HTTP) | 前端呈現 |
|---|---|---|
| 金額超過訂單金額 | `REFUND_EXCEEDS_TOTAL` (422) | 對話框欄位錯誤 |
| 重複退款 | `ALREADY_REFUNDED` (409) | toast + 關閉 |
| 訂單不存在 | `NOT_FOUND` (404) | 詳情 error 態 |

## 3. API 層規劃

### client 函式（typed · `$fetch<T>` · 回傳 `z.infer`）
| 函式 | endpoint | 回傳型別 |
|---|---|---|
| `listOrders(): Promise<Order[]>` | `GET /orders` | `Order[]` |
| `getOrder(id: string): Promise<Order>` | `GET /orders/{id}` | `Order` |
| `applyRefund(id: string, amount: number): Promise<RefundResult>` | `POST /orders/{id}/apply-refund` | `RefundResult` |

### Zod schema（搬 openapi 約束）
| schema | 關鍵驗證 |
|---|---|
| `OrderSchema` | `amount: positive()`, `status: enum(['待付款','已付款','已出貨','已取消','已退款'])` |
| `RefundRequestSchema` | `amount: positive().max(order.amount)` |

### fixtures（取自 clarified.md 範例）
`orders.normal`（3 筆）、`orders.empty`、`order.refundable`（已付款）、`order.alreadyRefunded`（已退款）

### MSW handlers
| handler | 回應分支 |
|---|---|
| `GET /orders` | 200 normal / empty |
| `GET /orders/:id` | 200 refundable / 404 |
| `POST /orders/:id/apply-refund` | 200 / 422 超額 / 409 重複 |

## 4. Handoff 重點

- 綁定覆蓋：3 畫面、4 互動全部有歸宿，無懸空；承載元件 / composable 皆 typed（§0），無 `any`。
- **規劃非實作**：實際 `.ts` 由 `athena-auto-frontend-msw-api-layer` 落地。
- **棧差異**：MSW/Zod 框架無關可沿用；消費端為 **Nuxt 4 composable**（`useFetch`/`$fetch`，非 React hook），dev/test 為 Vite + Vitest + `@nuxt/test-utils`——下游實作 skill 目前為 Next/React，需校正。
- 待釐清：列表分頁規格未定（沿用 screens 的待釐清）。
