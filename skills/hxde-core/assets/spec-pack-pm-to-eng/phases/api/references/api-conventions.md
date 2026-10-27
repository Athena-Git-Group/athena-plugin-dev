# API 契約慣例 · 細則

> 配合 `SKILL.md` 的非協商規則與完成判準。
> 命名 / 錯誤格式 / 版本為**預設建議（團隊可覆寫）**；團隊有既有 API 規範時以團隊為準，並於 handoff 標明採用了哪一套。

## 1. 行為 → method / path 完整對照

承 `SKILL.md` 的核心表，補齊邊界樣式：

| 需求行為 | 方法 | 路徑樣式 | 成功碼 | 備註 |
|---|---|---|---|---|
| 列表查詢 | GET | `/resources` | 200 | 回傳陣列；分頁本版範圍外 |
| 單筆查詢 | GET | `/resources/{id}` | 200 | |
| 建立 | POST | `/resources` | 201 | 回傳建立後的資源 + `Location` header |
| 全量取代 | PUT | `/resources/{id}` | 200 / 204 | 冪等；缺欄位即清空 |
| 部分更新 | PATCH | `/resources/{id}` | 200 | 只送要改的欄位 |
| 刪除 | DELETE | `/resources/{id}` | 204 | 無 body |
| 子資源列表 / 建立 | GET / POST | `/resources/{id}/children` | 200 / 201 | 從屬關係用巢狀路徑 |
| 領域動作（無法對應 CRUD） | POST | `/resources/{id}/{action}` | 200 | `action` 用動詞（`checkout` / `approve` / `cancel`） |

判斷順序：**先試標準 CRUD → 塞不進去才用領域動作**。不要把單純的 update 包成 action 路徑。

## 2. 狀態碼決策表（完整）

| 情境 | 碼 |
|---|---|
| 建立成功 | 201 |
| 查詢 / 更新成功（有 body） | 200 |
| 成功無 body（DELETE / 某些 PUT） | 204 |
| 請求語法 / 型別 / 缺必填欄位 | 400 |
| 通過格式但違反**業務驗證**（如金額超上限、狀態不允許） | 422 |
| 未認證 | 401 |
| 已認證但無權限 | 403 |
| 資源不存在 | 404 |
| **樂觀鎖衝突**（`version` 不符） | 409 |
| **唯一鍵衝突**（撞 UNIQUE / partial unique） | 409 |
| **狀態機非法轉移** | 409 |
| 伺服器錯 | 500 |

> 409 三種來源都對應 db_table 的機制：`version` 樂觀鎖、`UNIQUE` / partial unique、data_model 的合法轉移表。

## 3. 正規 Error schema（預設：自訂 `{code, message, details}`）

全 API **共用單一** Error schema，所有錯誤 response 都 `$ref` 它：

```yaml
components:
  schemas:
    Error:
      type: object
      required: [code, message]
      properties:
        code:    { type: string, example: VALIDATION_FAILED }   # 機器可讀的錯誤碼
        message: { type: string, example: "金額不可為負" }        # 人類可讀訊息
        details:
          type: array
          items:
            type: object
            properties:
              field: { type: string, example: amount }
              issue: { type: string, example: "must be >= 0" }
```

- `code` 用大寫底線常數（`NOT_FOUND` / `VALIDATION_FAILED` / `CONFLICT` …），同一 code 對應同一 HTTP 狀態碼。
- `details` 給欄位級錯誤（422 驗證失敗時逐欄列出），其他錯誤可省略。
- **替代方案**：團隊若採 RFC 7807 `application/problem+json`（`type` / `title` / `status` / `detail` / `instance`），整套換掉本 schema 並於 handoff 標明——但**二選一、全 API 一致**，不可混用。

## 4. 命名慣例（預設建議，團隊可覆寫）

- **path**：`kebab-case`、資源用**複數名詞**（`/purchase-orders`，不用 `/getPurchaseOrder`）。
- **path 參數**：`{resourceId}` 形式（`/orders/{orderId}/items/{itemId}`）。
- **operationId**：`exposes 操作名 + entity`（單數）、`camelCase`，全檔唯一（`listOrder` / `readOrder` / `createOrder` / `updateOrder` / `deleteOrder`；領域動作 `orderApplyRefund`）。**path 用複數 base、operationId 用單數 entity**。
- **JSON 欄位**：API 對外一律 `camelCase`。

### DB `snake_case` → API `camelCase` 對照

erm.dbml 的欄位是 `snake_case`，API schema 是 `camelCase`，逐欄機械對應：

| DB 欄位（erm.dbml） | API 欄位（schema） |
|---|---|
| `order_id` | `orderId` |
| `created_at` | `createdAt`（通常**不曝**，見 §5） |
| `unit_price` | `unitPrice` |

> 只改大小寫風格，**不改語意、不改型別**。對應關係是純機械的，不要趁機改名。

## 5. DTO ↔ entity 對應規則（schema 是視圖，不是 DB 表）

API schema 是實體的 **DTO 視圖**，依操作不同形狀不同：

| 操作 | schema 形狀 |
|---|---|
| **建立 request**（POST body） | 去除 server 生成欄位（`id` / `createdAt` / `updatedAt`）；去除持久化機制欄位；只留 client 該提供的 |
| **更新 request**（PUT / PATCH body） | 同上；PATCH 全部 optional，PUT 為完整可寫欄位 |
| **read response** | 業務需要看到的欄位；含 derived 屬性；**不**含機制欄位與未授權 PII |

### 一律隱藏的欄位（除非需求明確要曝）

- **持久化機制欄位**：`version`（樂觀鎖）、`deleted_at`（soft-delete）、純內部 FK、稽核欄位 `created_by` / `updated_by`（除非需求要顯示）。
- **PII**：依 data_model 的 PII 標記；未授權情境遮罩或不回傳，handoff 註明。
- **derived 屬性**：放 **response**（值由 server 算），**不**出現在 request。

> 樂觀鎖若需讓 client 帶 `version` 做衝突偵測，慣例走 `If-Match` / `ETag` header 或明確的 `version` 欄位——由需求觸發才加，並於 handoff 標明。

## 6. 驗證約束對照（data_model → OpenAPI）

把 data_model 的資料維度落成 OpenAPI 驗證關鍵字，讓下游 gherkin 能寫邊界 / 錯誤路徑：

| data_model 維度 | OpenAPI 關鍵字 |
|---|---|
| optionality（必填 / 可空） | `required: [...]` / 欄位 `nullable: true` |
| 值域上下限（金額、數量） | `minimum` / `maximum` / `exclusiveMinimum` |
| 字串長度 | `minLength` / `maxLength` |
| 格式（email / date-time / uuid） | `format` |
| 樣式（電話、代碼） | `pattern`（regex） |
| enum 封閉集合 | `enum: [...]`（值集合與 data_model 一致、無遺漏） |
| 數值精度（金額） | `type: number` + `format`／註明精度 |

> 缺值域 / 格式時**不自填**——標 `待釐清` 回報（對齊 SKILL 非協商規則 #4）。

## 7. 版本策略（預設：路徑前綴）

- OpenAPI 版本預設 **3.1**（團隊既有為 3.0 時沿用）。

## 8. 範圍外（本版不做，需求觸發時 handoff 標「待後續」）

- **認證 / 授權**：`securitySchemes`、各 endpoint 的 `security`、scope / 角色。
- **分頁 / 篩選 / 排序**：列表 query 的 `page` / `size` / cursor、`filter` / `sort` 參數。
