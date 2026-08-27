---
name: gherkin
description: >
  PM → 工程化流水線的階段 4（終點，前後端共用）。讀取已釐清的需求與上游工程文件，
  產出可執行規格化文件（Gherkin .feature，含 Scenario / Scenario Outline + Examples）。
  依 target 分變體：後端（步驟對齊 openapi.yaml + erm.dbml，由 API/DB 驗證）；
  前端（步驟描述畫面互動，對齊 screens + ui_contract）。產出的 .feature 是 runner-agnostic，
  下游用哪個機制驗證由 arguments.yml 的 frontend_verify 決定（mcp / playwright / agent-browser / vitest）。
  由 pm-to-eng-flow 編排器以全新 agent 觸發，也可獨立使用。
  前提：clarify 已 RESOLVED、對應 track 的上游 artifact 已產出。
---

# gherkin · 可執行規格（階段 4 / 終點）

> 流水線位置：score(gate) → clarify(gate) → 結構層 → 契約層 → **gherkin**。
> 前後端共用同一 stage，依 target 走不同變體。

## 本版三理念（與一般 BDD 的差異）

1. **Spec by Example** — 每個場景用 clarified.md 的**真實範例資料**寫具體值，不寫抽象斷言。抹消「合理金額」這類各自腦補的模糊，下游 red/green 的 AI 才有確定輸入。
2. **邊界優先（QA shift-left）** — 邊界 / 錯誤情境是第一級公民，**排在 happy path 之前**。用「寫測試」的動作去稽核需求完整度，最早期逼出 PM 沒講清楚的規則。
3. **善用場景大綱** — 同規則的多案例（正常 + 邊界 + 錯誤）收進 `場景大綱` + `例子`，資料驅動。

## 先讀（references/）

- `references/gherkin-guide.md` — 中文 Gherkin 撰寫指南（語言設定、切分、Spec by Example、邊界優先排序、缺則回報）。
- `references/scenario-outline-guide.md` — `場景大綱` / `例子` / Data Table 決策與寫法。
- `references/boundary-checklist.md` — QA shift-left 邊界檢查表（逐類掃 + 缺則回報迴圈）。
- `references/example.feature` — 完整中文示範（訂單退款，呼應 api stage 的 orders 例子）。
- 後端步驟對齊：`../api/references/api-conventions.md` §2（狀態碼）、§3（Error schema）。

## target 變體

| | 後端變體 | 前端變體 |
|---|---|---|
| 步驟描述 | 對 API / 資料的行為 | 畫面互動（在畫面 X 點 Y，看到 Z / 導到 W） |
| 對齊對象 | openapi.yaml + erm.dbml | screen-map + ui-contract（+ openapi.yaml、+ design 視覺原型） |
| 驗證方式（下游執行） | API / DB 斷言 | 依 `frontend_verify`：mcp / playwright / agent-browser / vitest+testing-library |

> fullstack：兩套變體由**兩個 gherkin agent** 各自產出，分寫 `gherkin/backend/` 與
> `gherkin/frontend/`（避免互蓋），handoff 也分 `gherkin-backend.md` / `gherkin-frontend.md`。

## .feature 是 runner-agnostic（驗證是下游的事）

本階段只產**可執行規格**，不負責跑它——實際執行/驗證屬下游（athena-auto-red/green、
e2e-runner 等）。所以 `.feature` 不綁特定 runner：
- 步驟用「使用者行為」措辭（在畫面 X 點 Y，看到 Z），不寫死某 runner 的 API。
- 前端用哪個機制驗證由 `arguments.yml` 的 `frontend_verify` 決定，本階段在 handoff 標注即可：
  `mcp`（Chrome DevTools MCP，agent 即時驗 + 除錯）/ `playwright`（CI 回歸）/
  `agent-browser`（Vercel Agent Browser）/ `vitest-testing-library`（元件層）。
- `frontend_verify` 未指定時，仍照常產 `.feature`，handoff 標「建議機制」。

## 輸入

- `specs/<slug>/clarify/clarified.md`（共用）——**特別是其「範例資料」與「邊界」段**：
  - **範例資料**（每個核心實體 ≥3 筆真實資料）是 Spec by Example 的素材來源，直接餵進 `例子` 表。
  - **邊界 / 規則 / 狀態轉移 / 唯一性**是邊界優先場景的依據。
- 後端：`specs/<slug>/db_table/erm.dbml` + `specs/<slug>/api/openapi.yaml`
  ——openapi 的驗證關鍵字（`minimum`/`maximum`/`minLength`/`pattern`/`enum`/`required`）是**邊界判定值的權威來源**（見 boundary-checklist）。
- 前端：`specs/<slug>/screens/screen-map.md` + `specs/<slug>/ui_contract/ui-contract.md`（+ `specs/<slug>/api/openapi.yaml` 若存在、+ `specs/<slug>/design/` 視覺原型若有，供視覺斷言）

## 輸出

- 單一 target：`specs/<slug>/gherkin/<feature>.feature` + `specs/<slug>/handoffs/gherkin.md`
- **fullstack（兩變體分流，避免互蓋）**：
  - 後端：`specs/<slug>/gherkin/backend/<feature>.feature` + `handoffs/gherkin-backend.md`
  - 前端：`specs/<slug>/gherkin/frontend/<feature>.feature` + `handoffs/gherkin-frontend.md`

## 執行步驟

1. **讀齊輸入** — clarified.md（重點：範例資料 + 邊界 / 規則 / 狀態轉移 / 唯一性）、對應 track 的上游契約（後端 openapi.yaml + erm.dbml；前端 screen-map + ui-contract）。缺必要 artifact → 回報並中止。
2. **切分 Feature / Rule** — 一個業務能力一個 `功能`；clarified.md 的每條規則一個 `Rule` 區塊。Feature 開頭寫「角色 + 目標 + 效益」。（細則：`gherkin-guide.md` §2）
3. **每條規則先掃邊界（QA shift-left）** — 用 `boundary-checklist.md` 逐類掃出該規則**真正存在**的邊界 / 錯誤點（值域、長度、必填、enum、格式、業務驗證、狀態機非法轉移、唯一鍵、不存在…），判定值對齊 openapi 驗證關鍵字與 clarified.md。
4. **寫場景，邊界 / 錯誤排前** — 同步驟、只有值在變的多案例 → `場景大綱` + `例子`（邊界 / 錯誤列在前，標 `@error`/`@boundary`/`@happy`）；步驟結構不同的錯誤路徑 → 各寫獨立 `場景`。（`scenario-outline-guide.md`）
5. **填具體值（Spec by Example，嚴格溯源）** — 判定值取自 clarified.md 範例資料 / openapi 約束，**不自編**；點綴值可用擬真值。每個判定值記下來源供覆蓋矩陣回指。（`gherkin-guide.md` §4）
6. **缺則回報，不腦補** — 掃邊界時若遇需求未定義的規則 / 值：場景標 `@待釐清` + `# 待釐清:<問題>`，**不填值**，列入 handoff 的「回饋訊號」段。（`gherkin-guide.md` §7）
7. **Given/When/Then 對齊上游、措辭 runner-agnostic** — 後端對 openapi 請求/回應 + erm.dbml 實體狀態；前端對 screen-map 畫面/導航 + ui-contract 互動。用使用者行為措辭，不寫死 runner API。每支 .feature 第一行 `# language: zh-TW`。
8. **輸出 .feature + handoff** — handoff 含：覆蓋矩陣（規則 × 場景 × 來源）、未覆蓋項、**回饋訊號（待釐清缺口，PM-friendly 問句）**、前端標注建議 `frontend_verify` 機制。

## 完成判準

- [ ] 每支 .feature 第一行為 `# language: zh-TW`，關鍵字全用 zh-TW（見 `gherkin-guide.md` §1）。
- [ ] clarified.md 每條規則至少有一個對應 `Rule` 區塊與場景。
- [ ] 每條規則的邊界 / 錯誤路徑已依 `boundary-checklist.md` 掃過，且**排在 happy path 之前**。
- [ ] 場景中的判定值皆具體且可溯源（clarified.md 範例 / openapi 約束）——**無抽象值、無自編判定值**。
- [ ] 同步驟多案例用 `場景大綱` + `例子`，未用複製貼上的多個 `場景`。
- [ ] 每個場景：單一 `當`、可驗證的 `那麼`、措辭 runner-agnostic。
- [ ] 步驟可對應上游 artifact（後端：endpoint / 實體；前端：畫面 / 互動）。
- [ ] 需求未定義的邊界已標 `@待釐清` 並列入 handoff 回饋訊號——**未自行填值**。
- [ ] handoff 含覆蓋矩陣、未覆蓋項、回饋訊號。

## 非協商規則

1. **絕不腦補** — 場景只描述需求已定義的行為；遇未定義的規則 / 邊界 / 判定值，標 `@待釐清` 回饋，**不杜撰、不自填值**。
2. **判定值必溯源** — 影響通過 / 失敗的值必須回指 clarified.md 範例或 openapi 約束；點綴值才可用擬真值。
3. **邊界優先** — 每條規則的邊界 / 錯誤場景排在 happy path 之前，不得只寫 happy path。
4. 缺少對應 track 的必要上游 artifact 時，回報並中止。
5. `.feature` 維持 runner-agnostic（步驟用使用者行為措辭，不綁特定 runner API）。
