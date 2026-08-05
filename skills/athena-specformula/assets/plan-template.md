---
plan: ${PLAN_SLUG}
phases:
  - id: "01"
    name: Requirement Analysis
    depends_on: []
  - id: "02"
    name: Entity Modeling
    depends_on: ["01"]
  - id: "03"
    name: BDD Analysis
    depends_on: ["02"]
  - id: "04"
    name: API Contract
    depends_on: ["03"]
  - id: "05"
    name: Backend TDD Track
    depends_on: ["04"]
  - id: "06"
    name: Frontend Build Track
    depends_on: ["04"]
  - id: "07"
    name: Frontend E2E
    depends_on: ["06"]
  - id: "08"
    name: Integration Validation
    depends_on: ["05", "07"]
status_source: folders
---

# 工程計畫：${REQUIREMENT_TITLE}

> **狀態**: DRAFT
> **建立日期**: ${DATE}
> **最後更新**: ${DATE}
> **技術棧**: ${LANG} (${TEST_STRATEGY})
> **需求摘要**: ${REQUIREMENT_SUMMARY}

---

## Dependency Graph

> **機械真相聲明**：本檔頂部的 YAML frontmatter 是 Dependency Graph 的**唯一機械真相**
> （由 `scripts/validate_plan.py` 解析與驗證）。下方的 markdown 表格與 ASCII 圖只是
> **人類視圖**，必須與 frontmatter 一致，否則 validator 會報 error。
> `status_source: folders` 表示 phase 狀態的唯一真相是卡片所在的 `todo/` / `doing/` /
> `done/` 資料夾；表格中的「狀態」欄僅供人類瀏覽。

| Phase | Name | Depends On | 狀態 |
|-------|------|------------|------|
| 01 | Requirement Analysis（需求分析 + 影響評估 + 行為設計） | — | todo |
| 02 | Entity Modeling（外部品質 — 資料） | 01 | todo |
| 03 | BDD Analysis（外部品質 — 可執行規格） | 02 | todo |
| 04 | API Contract（內部品質） | 03 | todo |
| 05 | Backend TDD Track | 04 | todo |
| 06 | Frontend Build Track | 04 | todo |
| 07 | Frontend E2E（mock mode） | 06 | todo |
| 08 | Integration Validation | 05, 07 | todo |

```
01 → 02 → 03 → 04 ──┬──→ 05 ──┐
                     │         │
                     └──→ 06 → 07 ──→ 08
                                      ↑
                               05 ────┘
```

## 線性執行順序（建議）

> 若無平行資源，依此順序逐一執行。
> Phase 05 和 06 可平行（都只依賴 04）；Phase 07 依賴 06；Phase 08 依賴 05 + 07。

1. 01-requirement-analysis
2. 02-entity
3. 03-bdd-analysis
4. 04-api-contract
5. 05-backend-tdd（可與 06 平行）
6. 06-frontend-build（可與 05 平行）
7. 07-frontend-e2e
8. 08-integration

## Phase Card 欄位規格

每個 implementation phase（05-08）的 phase card 必須包含以下欄位，供 flow 的 phase loop 使用：

| 欄位 | 必要性 | 說明 |
|------|--------|------|
| **Depends On** | 必要 | 依賴的 phase 編號 |
| **Spec Sections** | 必要 | 此 phase agent 只需讀的 spec section 編號（避免全讀 1100+ 行 spec） |
| **Smoke Test** | 建議 | Phase 完成後的驗證指令（無則視為 PASS） |

### Phase Card 範例

```markdown
## Phase 05: Backend TDD Track

- **Depends On:** 04
- **Spec Sections:** 1, 3, 4
- **Smoke Test:** `cargo test && cargo clippy`
```

```markdown
## Phase 06: Frontend Build Track

- **Depends On:** 04
- **Spec Sections:** 2, 6
- **Smoke Test:** `npm run build && npm run test`
```

```markdown
## Phase 07: Frontend E2E（mock mode）

- **Depends On:** 06
- **Spec Sections:** 2, 6
- **Smoke Test:** `npm run test:e2e -- --mock`
```

```markdown
## Phase 08: Integration Validation

- **Depends On:** 05, 07
- **Spec Sections:** 7（或全部）
- **Smoke Test:** `npm run test:e2e`
```

## 品質框架

### Phase 01: Requirement Analysis（統一入口）

不區分 greenfield / 新功能 / 改變需求。每個需求都是 current state → desired state 的 delta。
Phase 01 產出 **Execution Plan**，決定 Phase 02-08 各自的工作範圍。

### External Quality（外部品質）— Phase 02~04

推理順序：**行為(01) → 資料(02) → 規格精煉(03) → 實作契約(04)**。

| Phase | 推理依據 |
|-------|---------|
| 01 → 02 | 有了行為（features）才能推導「作用在什麼實體上」 |
| 02 → 03 | 有了實體結構（erm.dbml）才能寫出精準的 Examples |
| 03 → 04 | 每個 command/query 天然對應一個 API endpoint |

### Implementation — Phase 05~08

Phase 01-04 的產出物是所有實作 Phase 的共同契約。

## 共同契約

Phase 01-04 的產出物是 Phase 05-08 的共同依據（Single Source of Truth）：

| 產物 | 路徑 | 消費者 |
|------|------|--------|
| Execution Plan | `${PLAN_DIR}/plan.md` | Phase 02-08（scope 依據） |
| Activity Diagrams | `${SPECS_ROOT_DIR}/activities/` | Phase 07（E2E 測試計畫結構） |
| Feature Files（含 Examples） | `${SPECS_ROOT_DIR}/features/` | Phase 05（TDD 循環）、Phase 07（操作/預期回饋提取） |
| erm.dbml | `${SPECS_ROOT_DIR}/entity/erm.dbml` | Phase 05（Schema Analysis） |
| api.yml | `${SPECS_ROOT_DIR}/api/api.yml` | Phase 05（Red 欄位守衛）、Phase 06（MSW handlers）、Phase 08（驗證基準） |

## Context Management

- 三層持久化：檔案系統（卡片）+ TodoWrite + Context Window
- Compact Proof 層次化：specformula 16 任務 / 各 Phase 內部自管細節
- Lazy Loading：每個 Phase 只載入當前 skill，跨 skill 必定重新 LOAD
- 詳見 skill `references/context-management.md`
