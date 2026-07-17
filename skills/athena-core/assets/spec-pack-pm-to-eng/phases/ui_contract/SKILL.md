---
name: ui_contract
description: >
  PM → 工程化流水線的階段 3（前端 track，對應後端的 api）。讀取已釐清的需求、
  畫面架構（screens）與設計師 `design/` HTML，推導前端的「互動契約」：把資料 / API
  綁到畫面元素 / 元件上——view model、互動 → 事件 → (API 呼叫 / 導航) 綁定；API-First 下即 Zod schema /
  fixtures / MSW handler / API client 的規劃（消費 openapi.yaml）。前端棧 **Nuxt 4 + TypeScript strict（禁 any）**，
  在此規劃所需的輕量元件 / composable 與其型別契約（前端**不畫 class diagram**，元件設計就落在這份綁定規劃裡）。
  由 pm-to-eng-flow 在 target = frontend / fullstack 時以全新 agent 觸發。前提：clarify 已 RESOLVED、screens 已產出。
---

# ui_contract · 互動契約（階段 3 / 前端 track）

> 流水線位置：score(gate) → clarify(gate) → screens → **ui_contract**(前端) → gherkin。
> 這是前端的「契約層」，對應後端的 api。差別：api 是伺服器端契約（產出方）；
> ui_contract 是前端怎麼**消費**契約、怎麼把畫面綁到資料與互動。
> **前端結構層只有 screens（不畫 class diagram）**——元件怎麼拆、各自 props/emits/型別契約，就在本階段的綁定規劃裡一併定（輕量、夠用即可），下游 Nuxt 4 實作據此落地。
> 前端技術棧 **Nuxt 4 + TypeScript strict（禁 any）**：view model = `composables/` 的 `use*`（+ `useState` / Pinia 視範圍）；導航 = `navigateTo` / `<NuxtLink>`；資料 = `useFetch<T>` / `$fetch<T>`；API 層 = Zod + MSW + typed client。完整規範見 `../pm-to-eng-flow/references/frontend-stack-conventions.md`。

## 先讀（references/）

- `../pm-to-eng-flow/references/frontend-stack-conventions.md` — **必讀**：Nuxt 4 慣例 + 嚴格型別（禁 any）規範。
- `references/view-model-binding-guide.md` — view model 格式 + 互動 → 事件 → (API/導航) 綁定表 + 錯誤碼對應（Nuxt 4 / typed）。
- `references/api-layer-guide.md` — Zod / fixtures / MSW / client 規劃格式，**及「規劃 vs 實作」邊界 + 下游實作 skill 的棧差異**。
- `references/example-ui-contract.md` — 完整示範（訂單退款）。

## openapi.yaml 是共享邊界

- 若 `specs/<slug>/api/openapi.yaml` **已存在**（fullstack 或後端先跑）→ **消費**它，長出 view model / Zod / MSW。
- 若**不存在**（純前端）→ 走 API-First：從 screens 的互動反推「這些畫面需要哪些 API」，
  產出所需的 API 表面當待辦，回報給使用者 / 後端。

## 輸入

- `specs/<slug>/clarify/clarified.md`
- `specs/<slug>/screens/screen-map.md`（畫面、扁平元件清單、導航、UI 四態——綁定的依據）
- `specs/<slug>/design/`（選讀，**設計師 Claude Design HTML**；有則對照版面/UX flow 決定要規劃哪些元件）
- `specs/<slug>/api/openapi.yaml`（若存在）

## 輸出

- `specs/<slug>/ui_contract/ui-contract.md`
  - 每個畫面的 view model（顯示什麼、送出什麼）+ 承載它的輕量元件 / composable 規劃（typed props/emits、容器 vs 展示，**夠用即可、不畫 class diagram**）
  - 互動 → 事件 → (API 呼叫 / 導航) 綁定表
  - API-First 規劃：Zod schema / fixtures / MSW handler / API client 對應（消費 openapi.yaml）
- `specs/<slug>/handoffs/ui_contract.md`（依 handoff-contract）

## 執行步驟

0. **讀棧規範** — 先讀 `../pm-to-eng-flow/references/frontend-stack-conventions.md`，確認 Nuxt 4 慣例與型別鐵則（禁 any）。
1. **盤點來源** — 讀 clarified.md、screen-map（＋ `design/` 視覺稿若有）；檢查 `api/openapi.yaml` 是否存在（決定走消費或 API-First 反推）。
2. **規劃承載元件 / composable**（取代已移除的 component_design）— 從 screen-map 的扁平元件清單（＋ `design/` 版面）為每畫面規劃**夠用**的容器 / 展示元件與 `use*` composable，標 **typed `defineProps<T>()` / `defineEmits<T>()`**。輕量即可、**不畫 class diagram**；簡單畫面可只標一個容器 + 一個 composable。
3. **定義 view model** — 對每個畫面列「讀什麼 / 送什麼」，每欄回指 openapi schema 欄位（型別以 `z.infer` 推導），對應到上一步規劃的容器元件 + composable。（`view-model-binding-guide.md` §1）
4. **綁互動** — 把 screen-map 每個可操作元素串成「互動 → **typed emit（`defineEmits<T>()`）** → 動作（composable / `useState` / Pinia 方法 → typed API client 呼叫 / `navigateTo`）」，**每個互動都要有歸宿**。（§2）
5. **對齊契約** — openapi 存在 → 消費它長出 view model / Zod / MSW；不存在 → 走 API-First，從互動反推「需要哪些 API 表面」當待辦回報後端。
6. **規劃 API 層四件套** — typed client 函式（對齊 operationId、`$fetch<T>`）/ Zod schema（搬 openapi 約束、型別用 `z.infer`）/ fixtures（取自 clarified.md 範例）/ MSW handler（覆蓋成功 + 錯誤碼）。**只規劃、不寫程式碼**。（`api-layer-guide.md`）
7. **接錯誤碼** — 互動的失敗分支對應後端 Error schema / 狀態碼，供下游 gherkin 前端場景驗證。（§3）
8. **輸出** — 寫 `ui_contract/ui-contract.md` + `handoffs/ui_contract.md`（綁定覆蓋、待補 API、**規劃非實作 + 下游實作 skill 棧差異**、待釐清）。

## 完成判準

- [ ] 每畫面有承載 view model 的元件 / composable 規劃，props/emits 皆 **typed（`defineProps<T>()` / `defineEmits<T>()`，無 any）**。
- [ ] 每個畫面有 view model，每個顯示 / 送出欄位回指明確來源（openapi schema 欄位、型別以 `z.infer` 推導）。
- [ ] 每個互動都對應到 API 呼叫 / 導航（`navigateTo`）/ UI 狀態切換，**無懸空互動**。
- [ ] API 層四件套（client / Zod / fixtures / MSW）清單齊全，client 對齊 operationId（typed `$fetch<T>`）、Zod 約束搬自 openapi。
- [ ] 互動失敗分支對應後端錯誤碼（不自創前端錯誤語意）。
- [ ] openapi 不存在時：API-First 反推的所需 API 表面已列為待辦回報。
- [ ] 全程無 `any`（含 `as any`）；外部 / 未知資料經 Zod / type guard 收斂。
- [ ] handoff 標明「規劃非實作」、Nuxt 4 棧與下游實作 skill 差異、待補 API、待釐清。

## references/

- `../pm-to-eng-flow/references/frontend-stack-conventions.md` — Nuxt 4 慣例 + 禁 any 型別規範（必讀）。
- `view-model-binding-guide.md` — view model + 互動綁定 + 錯誤對應格式（Nuxt 4 / typed）。
- `api-layer-guide.md` — Zod / fixtures / MSW / client 規劃格式 + 規劃vs實作邊界。
- `example-ui-contract.md` — 完整示範（訂單退款）。

## 非協商規則

1. view model 與綁定以 **openapi.yaml 為單一事實來源**（存在時），不另立平行模型；缺約束不自填，標待釐清。
2. **只產規劃，不寫實作程式碼** — 真正的 `.ts`（Zod/MSW/client）由下游 `athena-auto-frontend-msw-api-layer` 落地。
3. 用 **Nuxt 4 慣例**消費契約（`composables/` 的 `use*` / `useState` / Pinia / `navigateTo` / `useFetch`/`$fetch`），**全程 TypeScript strict、禁 any**（依 frontend-stack-conventions）；於 handoff 標明既有前端實作 skill（Next/React 假設）的棧差異。
4. 前端錯誤呈現對應後端錯誤碼，**不自創**前端專屬錯誤語意。
5. 元件 / composable 只規劃**夠用**的份量承載綁定，**不畫 class diagram、不過度設計**；前端結構層無 component_design 階段，元件設計就落在這份契約裡。
6. 缺少必要上游 artifact（clarified / screen-map）時，回報並中止。
