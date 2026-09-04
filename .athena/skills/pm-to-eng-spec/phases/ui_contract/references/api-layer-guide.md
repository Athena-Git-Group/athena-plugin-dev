# API 層規劃格式（Zod / fixtures / MSW / client）· Nuxt 4

> 配合 `SKILL.md`。本檔定義 ui-contract.md 怎麼**規劃** API 層四件套。
> 邊界：本階段產「規劃」（要哪些 schema / handler / client、對應哪個 endpoint），**實作**由下游 `athena-auto-frontend-msw-api-layer` 落地。兩者不重寫，互相引用。
> 型別鐵則（禁 any、`z.infer` 推導型別）見 `../../pm-to-eng-flow/references/frontend-stack-conventions.md` §2。

## 規劃 vs 實作（職責邊界）

| | ui_contract（本階段，規劃） | athena-auto-frontend-msw-api-layer（下游，實作） |
|---|---|---|
| 產出 | 清單 + 對應表（要建什麼、對哪個 endpoint） | 真正的 `.ts` Zod schema / MSW handler / client 函式 |
| 形態 | Markdown 表格 | 程式碼 |
| 真相 | openapi.yaml | ui-contract.md + openapi.yaml |

> ⚠️ 既有的 `athena-auto-frontend-*` skill 以 **Next.js + React** 為假設，但本專案前端是 **Nuxt 4**。MSW / Zod 與框架無關（可直接沿用）；client 的消費方（Nuxt `composables/` 的 `use*`，內用 `useFetch`/`$fetch`）與 dev/test 整合（Vite + Vitest + `@nuxt/test-utils`）需以 Nuxt 為準。規劃時於 handoff 標明此差異。

## 1. API client 函式清單（消費 openapi.yaml）

每個 endpoint 對一個 typed client 函式（內用 `$fetch<T>`，回傳型別 = `z.infer<typeof Schema>`，禁 any）：

| client 函式 | endpoint | 入參（typed） | 回傳型別 |
|---|---|---|---|
| `listOrders(): Promise<Order[]>` | `GET /orders` | – | `z.infer<typeof OrderSchema>[]` |
| `getOrder(id: string): Promise<Order>` | `GET /orders/{id}` | `id: string` | `Order` |
| `applyRefund(id: string, amount: number): Promise<RefundResult>` | `POST /orders/{id}/apply-refund` | `id: string, amount: number` | `RefundResult` |

- 函式名對齊 openapi `operationId`（`listOrder` / `readOrder` / `orderApplyRefund`）。
- client 被 Nuxt composable 消費（`useOrder` 內呼叫 `getOrder`），元件不直接呼叫。

## 2. Zod schema 清單（對齊 openapi 約束）

每個 DTO 一個 Zod schema，**驗證關鍵字直接搬 openapi**（讓前端驗證與後端契約一致）：

| Zod schema | 對應 openapi schema | 關鍵驗證（搬 openapi） |
|---|---|---|
| `OrderSchema` | `Order` | `id: string`, `amount: number().positive()`, `status: enum([...])` |
| `RefundRequestSchema` | `RefundRequest` | `amount: number().positive().max(訂單金額)` |
| `ErrorSchema` | `Error` | `code: string`, `message: string` |

- enum 值集合、min/max、必填，全部對齊 openapi（不自加、不漏）。
- 缺 openapi 約束時不自填，標 `待釐清`（對齊 api stage 的「缺值域不自填」）。

## 3. Fixtures 清單（測試 / MSW 假資料）

每個核心資源備正常 + 邊界 + 錯誤 fixture，**取自 `specify/spec.md`「資料維度與範例資料」段**（接上 Spec by Example）：

| fixture | 用途 |
|---|---|
| `orders.normal` | 列表 success 態（≥3 筆，來自 spec.md 範例資料） |
| `orders.empty` | 列表 empty 態（空陣列） |
| `order.refundable` | 詳情：狀態=已付款、可退款 |
| `order.alreadyRefunded` | 詳情：狀態=已退款（重複退款測試） |

## 4. MSW handler 清單（攔截 → 回 fixture）

每個 endpoint 一個 MSW handler，覆蓋成功 + 錯誤回應：

| handler | 攔截 | 回應 |
|---|---|---|
| `GET /orders` | 列表 | 200 `orders.normal` / 可切 empty |
| `GET /orders/:id` | 詳情 | 200 `order.refundable` / 404 `ErrorSchema` |
| `POST /orders/:id/apply-refund` | 退款 | 200 成功 / 422 `REFUND_EXCEEDS_TOTAL` / 409 `ALREADY_REFUNDED` |

- handler 的成功 / 錯誤分支要對齊 §view-model-binding §3 的錯誤對應，下游 gherkin 才驗得到。
- MSW 與框架無關，Nuxt（Vite dev server + Vitest + `@nuxt/test-utils`）可直接用。

## 5. ✅ / ❌

- ✅ client 對齊 operationId、typed（`$fetch<T>` / 回傳 `z.infer`）；Zod 約束搬自 openapi；fixtures 取自 spec.md 範例資料。
- ✅ handler 覆蓋成功 + 錯誤碼分支。
- ✅ handoff 標明「規劃，非實作」+ Nuxt 4 ↔ 下游（Next/React）棧差異。
- ❌ 在這階段寫真正的 `.ts` 程式碼（那是下游實作）。
- ❌ Zod 約束與 openapi 不一致，或自創 openapi 沒有的欄位 / 錯誤碼。
- ❌ client / schema 帶 `any`（回傳型別一律 `z.infer` 推導）。
