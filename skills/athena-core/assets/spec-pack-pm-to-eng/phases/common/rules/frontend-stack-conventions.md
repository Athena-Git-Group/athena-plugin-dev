# 前端技術棧與型別規範（Nuxt 4 · 共用合約）

> 跨前端階段（`screens` / `ui_contract` / 前端 `gherkin`）的**單一事實來源**。
> 各前端 skill 不重述技術棧細節，一律「依 frontend-stack-conventions」並引用本檔。
> 與 `handoff-contract.md` 同層，皆為 pm-to-eng-flow 的跨階段共用合約。

本團隊前端技術棧固定為 **Nuxt 4 + TypeScript（strict）**。所有前端規格產出（畫面、互動契約、Gherkin）一律以此棧的慣例描述，**不得**退回 Vue 3 裸專案、vue-router 手寫設定、或混入 Next.js / React idioms。

---

## 1. Nuxt 4 慣例（規格描述時的用語與假設）

### 1.1 路由與導航（檔案式路由）

- **畫面 = `pages/` 下的檔案**，不手寫 vue-router 設定。route 由檔名/目錄推導：
  - `pages/equipments/index.vue` → `/equipments`
  - `pages/equipments/[id].vue` → `/equipments/:id`（動態參數 `id`）
- **導航用 `navigateTo('/path')`**（程式式）或 **`<NuxtLink to="/path">`**（宣告式）——**不用** `router.push` / `<router-link>` 字樣。
- route 參數 / query 用 **`useRoute()`**（`const route = useRoute(); route.params.id`）。
- 頁面層級的 meta（layout、middleware、需登入）用 **`definePageMeta({ ... })`**。
- 需登入保護用 **route middleware**（`middleware/auth.ts` + `definePageMeta({ middleware: 'auth' })`）。

### 1.2 資料抓取

- 頁面/元件初始資料：**`useFetch<T>()`** 或 **`useAsyncData<T>(key, () => $fetch<T>(...))`**（SSR-aware、自帶 `data`/`pending`/`error`/`refresh`）。
- 事件驅動的命令式請求（送出表單、toggle）：**`$fetch<T>()`**。
- **一律帶回傳型別泛型**：`useFetch<Equipment[]>(...)`、`$fetch<RefundResult>(...)`，不留型別給推斷成 `any`。
- 不在元件內裸寫 `fetch`/`axios`；走 API client 函式（見 §1.5）。

### 1.3 狀態管理

由輕到重，依共享範圍選擇，**規格需寫明理由**：

| 範圍 | 機制 | 用在 |
|---|---|---|
| 單一元件內部 | `ref<T>()` / `reactive<T>()` | 表單暫存、開關旗標 |
| 跨元件（父子） | `defineProps<T>()` 下傳 + `defineEmits<T>()` 上拋 | 容器協調展示元件 |
| 跨頁面 / SSR 安全共享 | **`useState<T>(key, init)`**（Nuxt 內建） | 當前使用者、UI 語言、輕量共享狀態 |
| 複雜領域狀態 / 多動作 | **Pinia（`@pinia/nuxt`）** `defineStore` | 有多個 action / getter、需集中管理的領域資料 |

- **不用 `provide`/`inject` 當主要跨層狀態**（Nuxt 用 `useState` / composable 取代）。
- store / `useState` 的 key 與 state 形狀都要標型別，**不得** `useState('x')` 不帶泛型而落空成 `any`。

### 1.4 元件與 composable

- 元件放 **`components/`（auto-import，無需手動 import）**，命名 `PascalCase`。
- 可複用邏輯抽成 **`composables/`（auto-import）** 的 `use*` 函式（SRP）。
- props：**`const props = defineProps<Props>()`**（型別式宣告，**不用** runtime `defineProps({...})` 物件式）。
- emits：**`const emit = defineEmits<{ submit: [amount: number]; cancel: [] }>()`**（型別式，事件 payload 標型別）。
- 雙向綁定：**`defineModel<T>()`**（Vue 3.4+/Nuxt 4），**不用** `modelValue` prop + `update:modelValue` emit 手寫樣板。
- 別名：import 用 **`~/`** 或 **`@/`** 指向專案根（如 `~/composables/useEquipment`）。

### 1.5 API 層（與 athena-auto-frontend-msw-api-layer 銜接）

- API client 為 typed 函式，集中放 `~/api/`（或 `composables/api`），對齊 openapi `operationId`。
- client 回傳型別 = Zod schema 的 `z.infer<typeof Schema>`（見 §2.4），**不另立平行型別**。
- MSW / Zod 與框架無關，可直接沿用；**消費端為 Nuxt composable**（`useFetch`/`$fetch`），dev/test 整合為 **Vite + Vitest + @nuxt/test-utils**。

---

## 2. 型別規範（strict TypeScript · 禁 any）

> Nuxt 4 預設 `typescript.strict: true`。所有前端規格與下游實作**一律強型別**，把「型別未定」視為「待釐清」，不用 `any` 蒙混。

### 2.1 核心鐵則

1. **禁用 `any`**（顯式 `: any`、`as any`、隱式 any 皆禁）。ESLint `@typescript-eslint/no-explicit-any` 設為 `error`、`no-unsafe-*` 系列開啟。
2. 來源不明的外部值用 **`unknown`**，再以 type guard / Zod 解析**收斂**成具體型別後使用——不直接當 `any` 用。
3. **不靠斷言繞過型別**：避免 `as`；必要時用 **`satisfies`** 維持型別檢查，或寫 type guard（`value is T`）。
4. 函式（含 composable）的**回傳型別顯式標註**：`Ref<T>` / `ComputedRef<T>` / 自訂 interface，不放任推斷成寬鬆型別。
5. 可空與選填如實表達：`T | null` / `field?: T`，**不用** `any` 掩蓋 nullable。

### 2.2 元件型別

- props：`defineProps<{ order: Order; canRefund: boolean }>()`。
- emits：`defineEmits<{ submit: [amount: number]; cancel: [] }>()`（payload tuple 標型別）。
- `defineModel<number>()` / `defineModel<string | null>()`。
- slot props 若有，標 `defineSlots<...>()`。

### 2.3 Nuxt composable 型別

- `useState<UserSession | null>('session', () => null)` — **帶泛型**。
- `useFetch<Equipment[]>('/api/equipments')`、`$fetch<Equipment>(...)` — **帶泛型**。
- 自寫 composable 回傳標明：
  ```ts
  function useEquipmentList(): {
    equipments: Ref<Equipment[]>
    state: ComputedRef<'loading' | 'empty' | 'error' | 'success'>
    search: (q: EquipmentQuery) => Promise<void>
  }
  ```

### 2.4 資料型別以 Zod schema 為單一事實來源

- 後端契約存在（openapi.yaml）→ Zod schema 搬 openapi 約束；**TS 型別用 `z.infer<typeof EquipmentSchema>` 推導**，不手寫第二份 interface。
- 缺 openapi 約束（多語結構、query、跨欄位）→ **以 clarified 為準**並標 `待釐清`/`待補`，仍給出明確型別，**不退回 `any`**。
- 列舉用 `z.enum([...])` → `z.infer` 得 union 字面量型別，不用 `string`。

### 2.5 ✅ / ❌

- ✅ `defineProps<T>()` 型別式、`useFetch<T>`/`$fetch<T>` 帶泛型、composable 標回傳型別。
- ✅ 外部/未知資料先 `unknown` → Zod/type guard 收斂。
- ✅ 型別由 `z.infer` 從 schema 推導，單一事實來源。
- ❌ `: any` / `as any` / 不帶泛型的 `useState('k')` / `$fetch('url')`。
- ❌ 手寫第二份與 schema 平行的 interface（會漂移）。
- ❌ 用 `as` 硬轉繞過 strict 檢查（改用 `satisfies` 或 type guard）。

---

## 3. 規格描述用語對照（避免退回舊棧）

| 不要寫（Vue 3 裸 / React） | 要寫（Nuxt 4） |
|---|---|
| `router.push('/x')` / `<router-link>` | `navigateTo('/x')` / `<NuxtLink>` |
| 手寫 vue-router routes 設定 | `pages/` 檔案式路由 |
| `provide`/`inject` 當共享狀態 | `useState<T>()` / Pinia |
| runtime `defineProps({ ... })` | 型別式 `defineProps<T>()` |
| `modelValue` + `update:modelValue` 手寫 | `defineModel<T>()` |
| callback 當 prop 傳（React idiom） | `defineEmits<T>()` 往上拋 |
| 元件內 `fetch`/`axios` | API client + `useFetch`/`$fetch` |
| `: any` / `as any` | 具體型別 / `unknown`+收斂 / `z.infer` |
