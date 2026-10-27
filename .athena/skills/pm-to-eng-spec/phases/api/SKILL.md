---
name: api
description: >
  PM → 工程化流水線的後端 track · 前後端共享契約。採**編譯器模型**：
  AI 從已釐清的需求產出結構化的 **API intent DSL**，
  再由**確定性 transpiler**（scripts/openapi.py）把 intent DSL + erm.dbml 編譯成 OpenAPI 3.0.3 的 openapi.yaml。
  openapi.yaml 是 build artifact、不可手改——要改 API 就改 DSL 重編。schema 為實體的 DTO 視圖
  （response 全欄位 / Request 去除 PK 與系統欄位），由 transpiler 機械產生。
  由 pm-to-eng-flow 編排器以全新 agent 觸發，也可獨立使用。
  前提：specify 已 READY、data_model / db_table（erm.dbml）已產出。
---

# api · API Contract（後端 track · 編譯器模型）

> 流水線位置：score(gate) → clarify(gate) → specify(gate) → data_model →（class_diagram ∥ db_table）→ **api** → gherkin。
> 本 phase 是**伺服器端契約的產出方**；前端 `ui_contract` 與後端 `gherkin` 消費 openapi.yaml。

## 架構：編譯器模型（這是本 skill 的核心）

```
原始碼（AI 寫、人審查）              編譯器（確定性、純函數）            產物（不可手改）
api-intent（*.intent.yaml）─┐
erm.dbml（annotated）      ─┼──►  scripts/openapi.py  ──►  api/openapi.yaml
                                                                    （要改 → 改 DSL 重編）
```

- **判斷在 DSL**：哪些資源、開哪些端點、有哪些領域動作——AI 的創造性工作只在這裡，且結果是**可審查的小檔**。
- **生成是機械的**：path 推導、DTO 雙 schema、狀態碼/錯誤格式、命名（snake→camel）全部由 transpiler 強制。同輸入同輸出、可重現、零 LLM token。
- **openapi.yaml 不可手動編輯**：手改會在下次重編時被覆蓋、且造成 drift。要改一律改 DSL。

## 本版範圍

- **涵蓋**：REST 資源端點（exposes 驅動）、DTO request/response schema、狀態碼、共用 Error。
- **範圍外（本版不做，但不靜默丟失）**：認證/授權（intent DSL 的 `access` 區塊與 securitySchemes）、分頁/filter/sorting（`exposes.list`）。
  需求明顯觸發時 → **於 handoff 標「待後續」**，DSL 暫不寫這些區塊，不自行半套實作。

## 輸入

> 優先序：**行為與資源以 `specify/spec.md` 為準**；**欄位型別 / 值域 / enum / 機制欄位以 erm.dbml + data_model 為準**。歧義回查上游、仍不足則回報，**絕不腦補**。

- `specs/<slug>/specify/spec.md`（**行為 / 規則真相**；首行 STATUS 必須為 READY）——
  其 FR / 全域需求 / 邊界情況即資源與行為的來源。
- `specs/<slug>/db_table/erm.dbml`（**transpiler 的型別來源**；annotated DBML，含 enum / note / pk / not null）。
- `specs/<slug>/data_model/data-model.md`（enum 封閉集合 / derived / PII 標記，輔助判斷 DSL 該開哪些操作）。
- `specs/<slug>/class_diagram/class-diagram.mmd`（選讀，Controller 方法 → 操作的線索）。

## 輸出

- `specs/<slug>/api/<resource>.intent.yaml`（**AI 產出**：每個資源一份 API intent DSL）。
- `specs/<slug>/api/openapi.yaml`（**transpiler 產出**：OpenAPI 3.0.3，不可手改）。
- `specs/<slug>/handoffs/api.md`（依 `phases/common/rules/handoff-contract.md` 的格式）：列資源/端點清單、關鍵 intent 決策、**範圍外待後續項**、假設。

## DSL 撰寫規約（重點，完整見 rules/）

- **base = `api` 值**，kebab-case、用**複數名詞**（`api: orders` → `/orders`、`/orders/{id}`）；entity 仍用單數 Table Name。
- **entity 照抄 DBML Table Name**，不改大小寫、不加複數（`Order` / `OrderItem` / `CustomerProfile`）。
- **path / method 只在 `exposes`**；`standard` 的路徑由慣例推導，不要手寫 path。
- 領域動作放 `exposes.operations`，字串 → `POST /{base}/{id}/<name>`；或 `{name, method, path}` 顯式指定。
- **禁止**：自創頂層 `endpoints:`、把 path/method 寫進 `access`、deprecated `access.permissions`（transpiler 會直接報錯擋下）。

## SOP

### Phase 1 -- 收斂資源與撰寫 DSL

1. READ 讀取 `specify/spec.md`（行為 / 規則真相，首行須為 `STATUS: READY`）、`db_table/erm.dbml`（transpiler 的型別來源）與 `data_model/data-model.md`（enum / derived / PII 標記），選讀 `class_diagram/class-diagram.mmd` 當操作線索。
2. THINK 從 spec.md 收斂出資源清單（對齊 data_model / erm.dbml 的實體）與每個資源的行為；歧義處回查上游，仍不足則標 `待釐清` 回報，不腦補。
3. WRITE 為每個資源寫一份 `*.intent.yaml`：`api`（複數資源 base，kebab）、`entity`（照抄 DBML Table Name，單數）、`exposes.standard`（CRUD 子集）、`exposes.operations`（塞不進 CRUD 的領域動作，帶 `method` / `path`）。撰寫前先讀取 `rules/dsl-format-anchor.md`（DSL 撰寫的唯一裁決者）；需要可跑的最小範例時讀取 `templates/example.intent.yaml`（搭配 `templates/example.dbml`）。
4. THINK 若需要確認 transpiler 編碼出的狀態碼、Error schema、DTO 規則、命名（snake→camel）等慣例的設計理由，讀取 `rules/api-conventions.md`。
5. THINK 若需要對照 `rules/dsl-format-anchor.md` 裁剪前的完整來源規格（含本版範圍外的 `access` 認證/授權與 `exposes.list` 分頁區塊的原始定義），讀取 `rules/haapi-format-anchor.md`；本版仍以 `rules/dsl-format-anchor.md` 為 DSL 撰寫的唯一裁決者。

### Phase 2 -- 編譯與驗證

6. WRITE 跑 transpiler：
   ```
   python3 phases/api/scripts/openapi.py \
     --intent specs/<slug>/api/ \
     --dbml  specs/<slug>/db_table/erm.dbml \
     --output specs/<slug>/api/openapi.yaml --title "<服務名>"
   ```
7. READ 驗證輸出：transpiler 自帶 `$ref` 解析檢查；另外用 `openapi-spec-validator` 或 `npx @redocly/cli lint` 確認 spec 合法。任一失敗 → 回到 Phase 1 修 DSL 或回報上游缺口，**不手改 openapi.yaml**；需要對照可跑的端到端範例輸出時讀取 `templates/example.openapi.yaml`。

### Phase 3 -- 交接

8. WRITE 依 `phases/common/rules/handoff-contract.md` 的格式寫 `handoffs/api.md`，列端點清單、intent 決策、範圍外待後續項與假設。
9. READ 回頭依「完成判準」逐項檢查 DSL 合法、行為覆蓋、契約完整度、schema 對齊、範圍外標注五個面向；不符合立即修正。

## 完成判準

**DSL 合法**
- [ ] 每份 `*.intent.yaml` 通過 transpiler 的格式檢查（無自創 `endpoints:`、`standard` 操作合法）。
- [ ] `entity` 對得上 erm.dbml 的 Table Name；`api` base 為 kebab、無複數。

**行為覆蓋（可追溯）**
- [ ] 需求每個 command / query 都在某資源的 `exposes` 裡有對應端點；無遺漏、無杜撰需求外的端點。

**契約完整度（transpiler 保證 + 抽查）**
- [ ] openapi.yaml 通過 `openapi-spec-validator` / redocly lint，且**每個 `$ref` 解得到**（transpiler 內建檢查）。
- [ ] 每個端點有 operationId、參數、成功 response 與對應錯誤 response（404 / 409 / 400 依操作類型）。

**schema 對齊（DTO 視圖）**
- [ ] response schema 欄位型別 / enum 與 erm.dbml 一致；Request schema 已去除 PK 與系統欄位（`created_at` / `updated_at` …）。
- [ ] 持久化機制欄位（`version` / `deleted_at`）未出現在任何 schema。

**範圍外（明確標注、不靜默丟失）**
- [ ] 認證/授權、分頁/filter/sorting 本版不涵蓋；需求觸發時於 handoff 標「待後續」，DSL 不半套。

## 非協商規則

1. **openapi.yaml 是 build artifact**：不可手動編輯；要改 API 一律改 `*.intent.yaml` / erm.dbml 後重跑 transpiler。
2. **判斷只在 DSL，生成全靠 transpiler**：不繞過 transpiler 手寫 OpenAPI；慣例（狀態碼/錯誤/DTO/命名）由 transpiler 強制、不靠人逐條遵守。
3. **DSL 遵循 Intent Format Anchor**（`rules/dsl-format-anchor.md`）：base=api 用複數名詞、entity 照抄 Table Name（單數）、path/method 只在 exposes；禁止格式由 transpiler 報錯擋下。
4. **絕不腦補**：資源 / 行為 / 型別，spec.md / erm.dbml 沒給的，標 `待釐清` 回報，不自填。
5. **範圍外不半套**：認證/授權、分頁/filter/sorting 若被需求觸發，於 handoff 標「待後續」，不靜默丟失也不自行實作。
6. `specify/spec.md` 的 STATUS 非 READY、或缺 erm.dbml 時，回報並中止。
7. `specs/<slug>/specify/spec.md` **缺失、為空、或首行非 `STATUS: READY`** 時，**回報並中止**——
   **不得**改讀 `clarify/` 的訪談產出、**不得**回頭讀 `source/requirement.md` 自行腦補、
   **不得**產出空 artifact 後宣告完成。
