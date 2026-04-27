# Build Handoff — add-athena-audit-requirement

- Gate Verdict: PASS
- Branch: feature/main_add_athena_skill_eval
- Point report: points/add-athena-audit-requirement.md
- Score: 7/30 (PASS-DIRECT-BUILD, Lightweight 路線：build → review-ship)

## Created

- skills/athena-audit-requirement-backend/SKILL.md
- skills/athena-audit-requirement-backend/references/scoring-rubric.md
- skills/athena-audit-requirement-backend/references/pm-question-templates.md
- skills/athena-audit-requirement-backend/assets/feedback-template.md
- skills/athena-audit-requirement-frontend/SKILL.md
- skills/athena-audit-requirement-frontend/references/scoring-rubric.md
- skills/athena-audit-requirement-frontend/references/pm-question-templates.md
- skills/athena-audit-requirement-frontend/assets/feedback-template.md
- handoffs/add-athena-audit-requirement-build.md（本檔）

## Modified

- README.md
  - 「Plugin 包含的 Skills」表格新增兩列（在 athena-skill-eval 後、git-conventions 前），均標為「輔導工具」+「—」
  - 新增 H2 章節 `## PM 需求驗收（athena-audit-requirement-{frontend,backend}）`，位置介於 `## L4 動態評估（athena-skill-eval）` 與 `## Weight Class（三層分流）` 之間
  - 新章節含 H3 細分：用法 / 後端 vs 前端視角 / PM Feedback 文件範例路徑 / 與其他 skill 的邊界
  - 「強制規則」段未動

## Self-smoke-test

- [x] 兩個 SKILL.md frontmatter 都不含 `stage` 欄位（`grep ^stage:` exit=1 確認）
- [x] 兩個 SKILL.md description 都明確劃線「不是 athena-point」（line 7 出現「這不是 athena-point」）
- [x] 兩份 rubric 維度名稱明顯不同
  - backend: Entity / State Transition / API Boundary / Business Rule / Data Validation / Integration Points
  - frontend: Actor / User Flow / Screen Inventory / Interaction / Visual Acceptance / Navigation
- [x] 兩份 feedback-template.md 主體不出現 RD 術語
  - 唯一出現「禁用詞：...」的位置是教學提示（告訴撰寫者哪些詞要避開），非實際範本內容
- [x] README 表格列數從 8 → 10（`grep -c '^| \*\*'` confirmed 10）
- [x] README 新增章節在 athena-skill-eval（line 207）之後、Weight Class（line 332）之前（line 268）
- [x] 不存在「verdict: X」「score: N/M」這種機器可解析欄位
  - SKILL.md 中出現 PASS / verdict 字串都在「我們**不**寫這些」的對比說明上下文（非協商規則 + 與 point 的劃線表）

## Design Decisions

1. **Rubric 採 0-3 分（總分 0-18）而非 0-30**：與 point 的 0-30 區隔，避免被誤用為 gate；分數陳述方式為「N 個維度給足、M 個維度需補」的自然語言，**對話與 feedback doc 都不出 yaml score 欄位**。
2. **Slug 推斷三層 fallback**：使用者 `--slug=` > PM 文件 H1 / 檔名 > `untitled-<timestamp>`，明寫在 SKILL.md 「Slug 推斷規則（決策樹）」段，避免每次跑都問使用者。
3. **PM feedback doc append 而非覆寫**：re-audit 時保留歷史，方便 PM 看補完進度。
4. **與 point 的劃線寫了 4 處**：(a) 兩個 SKILL.md description；(b) 兩個 SKILL.md「決策表 + 與 point 對比表」；(c) README 新章節「與其他 skill 的邊界」表；(d) README 新章節結尾的「更深劃線」段。各處強調點略有差異（觸發者 / 後果 / 是否寫 verdict）以避免機械重複。
5. **README 章節結構未平面化**：新章節用 H3 細分（用法 / 後端 vs 前端 / PM Feedback 文件 / 邊界比較），而非並列 4 個 H2。維持 README 整體可讀性。
6. **frontend rubric 對應 specformula Phase 01/06/07，backend rubric 對應 Phase 02/03/04**：每個維度都明列「對應 specformula Phase」幫助讀者交叉參照。
7. **Description 使用 trigger-word style**：兩個 description 都列出多個觸發詞（含中文短語與英文片段），符合 plugin 既有 skill 的 auto-delegation 慣例。

## Risks observed

- **與 athena-point Requirement Clarity 維度的功能重疊感**：point 已有 Requirement Clarity 0-5 分，本工具獨立評分可能讓初次接觸的使用者困惑「為什麼分兩次評」。已在 README 與 SKILL.md 多處劃線（point 服務 RD 開工決策；audit-requirement 服務 PM 需求驗收），但仍可能需在實際使用幾次後再迭代文案。
- **PM feedback doc 與既有 `clarify-loop` skill 的功能交集**：clarify-loop 是「依序澄清」的互動 skill，audit-requirement 是「一次性批次提問清單」的審計 skill，兩者風格上有重疊。本次未在 SKILL.md 寫對照，因為 clarify-loop 不在本 plugin 內（屬 user 安裝的其他 plugin），review 階段可考慮是否要加一句註解。
- **Rubric 第 2 維度 (State Transition / Data Validation) 在某些需求類型可能 N/A**：已在 backend rubric 標註「無狀態查詢 / 無驗證需求可標 N/A 並給 3 分」，但實際使用時 LLM 會不會誤判「N/A」需要實戰才知道。
- **README 章節數量已偏多**：plugin README 已有 6 個 H2 章節談各類 skill（含 audit / eval / 本次新增的 audit-requirement），未來再加新工具會需考慮統一收攏在「## 輔導工具」大章節下。本次未做這個重構（避免 scope 蔓延），標記為未來可整理項。
- **Feedback doc 寫入路徑沒做衝突檢測**：若 cwd 下已存在同名 doc，目前規則是「append Re-audit 區段」，但 SKILL.md 沒提供「讓使用者選擇覆寫 / append / 取消」的互動。實戰若 PM 用同一 slug 重跑多次可能 doc 會越長越亂。

## Not done (deliberately out of scope)

- 沒寫實作 case / eval test（這層由 athena-skill-eval 提供，team 自建即可）
- 沒在 marketplace.json 改動（plugin 自動掃 `skills/`，新 skill 應自動被識別）
- 沒寫 `references/mentoring-style.md` 副本（沿用 athena-skill-audit 的風格慣例，但 SKILL.md 已直接內嵌足夠的風格指引）

## Next Recommended Stage

`review` — Lightweight 路線下走 review-ship 合併 agent。
