# View Model + 互動綁定格式（Nuxt 4 · TypeScript strict）

> 配合 `SKILL.md`。本檔定義 ui-contract.md 怎麼寫「每個畫面讀什麼 / 送什麼」與「互動 → 事件 → (API / 導航)」。
> 前端技術棧 **Nuxt 4**：view model 由 `composables/` 的 `use*`（+ 視範圍 `useState` / Pinia）承載；導航用 `navigateTo` / `<NuxtLink>`。型別鐵則（禁 any）見 `../../pm-to-eng-flow/references/frontend-stack-conventions.md`。

## 1. View Model（每畫面：讀什麼、送什麼）

view model 是「畫面需要的資料形狀」，**對應到本契約規劃的容器元件 + composable**（前端無 component_design 階段，元件規劃就在本契約裡），欄位來源回指 openapi.yaml、型別以 `z.infer<typeof Schema>` 推導。

格式（每畫面一張表）：

| view model 欄位 | 顯示/送出 | 來源 | 對應元件 |
|---|---|---|---|
| `order.id` | 顯示 | `GET /orders/{id}` → `Order.id` | OrderInfoCard.props.order |
| `order.amount` | 顯示 | 同上 → `Order.amount` | OrderInfoCard.props.order |
| `order.status` | 顯示 | 同上 → `Order.status` | 狀態標籤 |
| `refundAmount` | 送出 | `POST /orders/{id}/apply-refund` body `amount` | RefundDialog.state.amount |

- **顯示**欄位來自 query/read response；**送出**欄位對應 command request body。
- 每個欄位都要能回指 openapi.yaml 的 schema 欄位（單一事實來源）；TS 型別用 `z.infer`，**不手寫平行 interface、不用 any**。
- view model 在 Nuxt 實作上 = composable 回傳的 typed reactive 物件（如 `useOrder(): { order: Ref<Order | null>; pending: Ref<boolean>; error: Ref<Error | null> }`，內部用 `useFetch<Order>` / `$fetch<Order>`）。

## 2. 互動 → 事件 → 動作 綁定表

把 screen-map 的每個「可操作元素」串成一條鏈：使用者操作 →（元件 emit 的）**typed 事件** → 容器處理 → API 呼叫或導航。

| 畫面 | 互動元素 | 事件（`defineEmits<T>()`） | 動作 | 結果 |
|---|---|---|---|---|
| 訂單列表 | 點某筆訂單 | `selectOrder: [id: string]` | `navigateTo('/orders/' + id)` | 導到詳情 |
| 訂單詳情 | 點「申請退款」 | `requestRefund: []` | 開 RefundDialog（`dialogOpen.value = true`） | 顯示 modal |
| 退款對話框 | 點「確認退款」 | `submit: [amount: number]` | `useRefund().submit()` → `$fetch<RefundResult>('POST /orders/{id}/apply-refund')` | 成功關 modal + `refresh()`；失敗顯示錯誤 |
| 退款對話框 | 點「取消」 | `cancel: []` | `dialogOpen.value = false` | 關 modal |

規約：
- **每個互動都要有歸宿**：不是 API 呼叫就是導航（或純 UI 狀態切換）。**無懸空互動**。
- 事件用**型別式 `defineEmits<{ ... }>()`**，payload 標型別（禁 any）；**不用 callback prop**（React idiom）。
- API 呼叫一律走 §API 層的 typed client 函式（見 `api-layer-guide.md`），**不在元件裡直接 `fetch` / `axios`**。
- 導航用 **`navigateTo` / `<NuxtLink>`**（Nuxt `pages/` 路徑）；條件導航標明條件。**不用** `router.push` 字樣。

## 3. 錯誤 / 邊界對應（接後端契約）

互動的失敗分支要對應後端錯誤碼（讓下游 gherkin 前端場景能驗）：

| 動作 | 後端錯誤碼 (HTTP) | 前端呈現 |
|---|---|---|
| 退款金額 > 訂單金額 | `REFUND_EXCEEDS_TOTAL` (422) | 對話框內欄位錯誤訊息 |
| 重複退款 | `ALREADY_REFUNDED` (409) | toast + 關閉對話框 |
| 訂單不存在 | `NOT_FOUND` (404) | 詳情頁 error 態 |

> 錯誤碼以 openapi.yaml 的 Error schema + `../../api/references/api-conventions.md` §2/§3 為準，前端不自創錯誤語意。

## 4. ✅ / ❌

- ✅ 每個 view model 欄位回指 openapi schema（型別 `z.infer`）；每個互動對應 API/導航/UI 狀態。
- ✅ 事件 typed（`defineEmits<T>()`）；API 呼叫走 typed client 函式（`$fetch<T>`），元件不直接 fetch。
- ✅ 失敗分支對應後端錯誤碼。
- ❌ 前端自立平行資料模型 / 手寫第二份 interface，不對齊 openapi。
- ❌ 互動沒有歸宿（點了沒反應 / 沒寫清楚做什麼）。
- ❌ 任何 `any` / `as any`，或 `router.push` / callback prop 等非 Nuxt 4 用語。
