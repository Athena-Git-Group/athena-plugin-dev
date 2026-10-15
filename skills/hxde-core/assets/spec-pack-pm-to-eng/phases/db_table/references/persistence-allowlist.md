# 持久化機制 allowlist · 細則

> 配合 `SKILL.md` 非協商規則 #2。這些欄位 / 結構是**持久化必需、不算擴張需求**，可逕自補。
> 型別與命名為**預設建議（團隊可覆寫）**；團隊有既有規範時以團隊為準。

## 1. 稽核欄位（audit）

| 欄位 | 型別（建議） | 何時需要 |
|---|---|---|
| `created_at` | `TIMESTAMP`（含時區依需求） | 幾乎每張交易表 |
| `updated_at` | `TIMESTAMP` | 會被更新的表 |
| `created_by` / `updated_by` | FK → 使用者 | 需追溯「誰做的」時 |

- master / reference 表可只留 `created_at`；純查詢結果表 / view 不需要。

## 2. 樂觀鎖（optimistic lock）

- `version`（`INT` / `BIGINT`，預設 0 或 1），每次更新 +1。
- 只在「同筆資料會被並發更新、且需防覆蓋」時加；單純 append 或低衝突表不必。

## 3. soft-delete

- `deleted_at TIMESTAMP NULL`（NULL = 未刪）優於 `is_deleted BOOLEAN`——保留刪除時間。
- **配套**：唯一性約束要改 **partial unique**（只在 `deleted_at IS NULL` 的列生效），
  否則「刪掉再建同 key」會撞唯一鍵。
- 是否用 soft-delete 由保存 / 法遵需求觸發，不要全表無腦套。

## 4. 代理鍵（surrogate key）

- 預設 `id BIGINT` auto-increment；需跨系統 / 不可預測 / 分散式產生時用 `UUID`。
- data_model 已有明確自然鍵時，自然鍵落成 `UNIQUE`，代理鍵仍可並存當 PK（看團隊慣例）。

## 5. N:M junction 物理落地

- 命名：兩端實體組合（如 `order_item`、`student_course`）。
- PK：複合 PK（兩端 FK）或獨立代理鍵 + 兩端 UNIQUE——看是否需被其他表引用。
- 兩端 FK **各自建索引**（查詢常從任一端出發）。

## 6. FK 行為對照（對齊 data_model 的「刪除行為」）

| data_model 業務語意 | FK 行為 |
|---|---|
| 刪上層、下層一起消失（組合） | `ON DELETE CASCADE` |
| 刪上層、禁止（還有下層就不能刪） | `ON DELETE RESTRICT` |
| 刪上層、下層保留但解除關聯 | `ON DELETE SET NULL`（該 FK 須可為 NULL） |

## 7. 索引

- 每個 FK 預設建索引。
- 複合索引遵守**最左前綴**：把最常獨立查詢、選擇度高的欄位放最左。
- 業務唯一性規則 → `UNIQUE`；條件式唯一 → `partial unique`。
- 避免冗餘：已被複合索引最左前綴覆蓋的單欄索引不必再建。

## 8. 邊界（不在此自動加，須由上游觸發）

- **多租戶 `tenant_id`**：只有 data_model / clarify 指明多租戶時才加，並納入相關唯一鍵與索引。
- **PII 加密 / 遮罩**：依 data_model 的 PII 標記與保存政策處理；本層不自行決定，handoff 註明。

---

## 命名慣例（預設建議，團隊可覆寫）

- 表名 `snake_case`；單複數依團隊既有規範統一（本檔不替團隊定）。
- FK 欄位 `<被參照實體>_id`（如 `user_id`）。
- 布林欄位 `is_` / `has_` 前綴；時間欄位 `_at` 後綴。
