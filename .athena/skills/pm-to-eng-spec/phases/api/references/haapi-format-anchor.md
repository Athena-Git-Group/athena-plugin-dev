# haAPI 格式錨點（Format Anchor）— api stage 精簡版

> 改編自 RAPTor 的 haAPI v3.3 anchor，**裁剪到本 stage 的範圍**：
> 移除 `access`（認證/授權）與 `exposes.list`（分頁/filter/sorting）——這兩塊本版不做（見 SKILL「本版範圍」）。
> 路徑/DTO/狀態碼由 `transpiler/openapi.py` 確定性產生；本檔是 DSL 撰寫的唯一裁決者。

---

## 核心：intent DSL 只宣告「能力」

| 區塊 | 負責 | 形狀 |
|------|------|------|
| `api` | 路徑 base | 字串（**複數名詞**、kebab-case） |
| `entity` | 對應 DBML Table | 字串（**照抄 Table Name，單數**） |
| `exposes.standard` | 開哪些 CRUD 端點 | 陣列（`list`/`read`/`create`/`update`/`patch`/`delete` 子集） |
| `exposes.operations` | 塞不進 CRUD 的領域動作 | 陣列（字串或 `{name, method, path}`） |

> path / method **只**出現在 `exposes`。`standard` 的 path 由慣例推導，不要手寫。
> **path 用複數 base、operationId 用單數 entity**（`/orders` + `listOrder`）。

---

## 最小合法範例

```yaml
api: orders                    # 路徑 base（複數名詞）
schema_version: "3.3"
entity: Order                  # 照抄 DBML Table Name（單數）
title: 訂單管理 API
description: 訂單的 CRUD + 業務操作

exposes:
  standard: [list, read, create, update, delete]
  operations:
    - { name: apply_refund, method: POST, path: "/{id}/apply-refund" }

source_evidence:
  - "clarify/clarified.md#訂單可被退款"
  - "db_table/erm.dbml#Table:Order"
```

> ⚠️ 含 `{` 的 path 在 flow 風格下**必須加引號**（`"/{id}/apply-refund"`），否則 YAML 解析失敗。

---

## 路徑推導規約（base = api，複數名詞）

transpiler 依此確定性推導，**不需在 DSL 寫 standard 的 path**：

```
base = api 值（複數名詞、已是 kebab；不再做任何轉換）
```

| exposes 來源 | path | method | operationId |
|-------------|------|--------|-------------|
| `standard: list`   | `/{base}`        | GET    | `list{Entity}` |
| `standard: create` | `/{base}`        | POST   | `create{Entity}` |
| `standard: read`   | `/{base}/{id}`   | GET    | `read{Entity}` |
| `standard: update` | `/{base}/{id}`   | PUT    | `update{Entity}` |
| `standard: patch`  | `/{base}/{id}`   | PATCH  | `patch{Entity}` |
| `standard: delete` | `/{base}/{id}`   | DELETE | `delete{Entity}` |
| `operations: - <name>`（字串） | `/{base}/{id}/<name>` | POST | `{entity}{Name}` |
| `operations: - {name, method, path}` | `/{base}` + 相對 `path` | 取 `method` | `{entity}{Name}` |

> 例：`api: orders` + `entity: Order` → list = `GET /orders`（`listOrder`）、read = `GET /orders/{id}`（`readOrder`）、apply_refund = `POST /orders/{id}/apply-refund`（`orderApplyRefund`）。

---

## entity 對應規則

完全照抄 DBML Table Name，**不改大小寫、不加複數**（複數只用在 URL 的 `api` base）。

| DBML Table | haAPI `entity:` | `api:` base（複數） |
|-----------|-----------------|---------------------|
| Order | Order | orders |
| OrderItem | OrderItem | order-items |
| CustomerProfile | CustomerProfile | customer-profiles |

---

## 禁止格式（transpiler 會直接報錯擋下）

```yaml
# ❌ HAAPI-SCHEMA-002：自創頂層 endpoints
endpoints: ...

# ❌ 把 path/method 寫進 standard（standard 只列操作名）
exposes:
  standard:
    - { name: list, path: /orders }   # 禁止！只寫 `list`

# ❌ 本版範圍外的區塊（先不要寫；需求觸發時於 handoff 標「待後續」）
access: ...          # 認證/授權
exposes:
  list: ...          # 分頁/filter/sorting
```

> 完整 v3.3（含 `access` v2 / `exposes.list`）以 RAPTor `DSLspec/haAPI-specification_v3.3.md` 為準；
> 本 stage 採用其子集，待 auth / 分頁納入範圍時再擴充本錨點與 transpiler。
