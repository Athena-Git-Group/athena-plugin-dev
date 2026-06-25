# Athena Flow — Loop Engineering 設計（v3：三圈閉環）

> **狀態**：設計提案（draft），尚未實作。團隊 review 後依「基座 → 2b → 3」順序落地。
> **定位**：承接 Flow v2（phase-level orchestration，已實作）的後續演進。v2 把 Build 拆成
> phase loop，強化的是**單發管線內部**；v3 在管線**外面**包兩個迴圈：何時啟動（2b）、如何學習（3）。
> **基建邊界**：純 Claude Code 原生（hooks / `/loop` / `ScheduleWakeup` / cron routines / subagents），
> 所有狀態存成 `.athena/` 內檔案，零外部依賴。

---

## 0. TL;DR

現在的 `/flow` 是一條**單發管線**：人工觸發 → point → stages → gates → done。
v3 在它外面加兩個迴圈，但**不重寫核心**：

- **Loop 2b（事件驅動）**：決定「何時把任務餵進管線」（CI 紅燈 / PR review / 排程 / inbox）。
- **Loop 3（自我改進）**：從累積紀錄學習，回頭改 skill / rubric / prompt / contract。

兩圈共用同一個底層物件 —— **Run Trace**。沒有它，3 無從學、2b 無從閉環。
所以落地順序被資料需求逼成：**基座（Run Trace + handoff GC）→ 2b → 3**。

---

## 1. 背景：三種 loop 與現況診斷

把 loop 分三種（對應 LangChain《The Art of Loop Engineering》四層）：

| 本設計分類 | LangChain | 一句話 |
|---|---|---|
| **Agent loop** | The Agent | model 在任務裡反覆 call tool 直到完成 |
| **Task-completion loop** | Verification Loop + Event Driven Loop | 觸發 → 執行 → 驗證 → 重試/停止/交人 |
| **Self-improvement loop** | Hill Climbing Loop | 分析每次執行的紀錄，回頭改善 agent 系統 |

疊到現在的 `athena-flow`：

| Loop | 現況 | 強度 |
|---|---|---|
| **1. Agent loop** | 每 stage/phase 開 fresh agent，內部 read→edit→smoke→fix。harness 只提供 tool-scope shell（`athena-stage-*`）+ smoke gate 契約 | 中 |
| **2a. Verification loop** | gate verdict + `verify-retry`（targeted re-build ≤2 輪）+ per-phase smoke gate + conflict detection | **強（現核心）** |
| **2b. Event-driven loop** | 幾乎沒有 — 全靠 `/flow <request>` 人工觸發。現有兩 hook（require-point / auto-commit）是*內部強制*，非*外部事件觸發* | **缺** |
| **3. Self-improvement loop** | `points/`、`handoffs/`、gate verdict、retry 次數全是現成 trace，但沒有東西回讀它們改系統。skill-audit / skill-eval 是靜態 + 與 flow 脫鉤 | **缺** |

**結論**：現在的 harness 是一條很完整的「單發任務完成管線」（2a 很強），缺的是
「何時自動啟動」（2b）與「怎麼從每次執行學習」（3）。v3 補這兩圈。

---

## 2. 設計總綱：一個基座、兩個外圈

關鍵洞察：**2b 與 3 共用同一個底層物件 —— Run Trace。**

- 事件驅動圈（2b）負責**何時把任務餵進管線**，每跑一次就**寫一筆 trace**。
- 自我改進圈（3）負責**從累積的 trace 學習、回頭改系統**，它**讀 trace、吐改進提案**，
  提案再以 intake 形式重新進 `/flow`。

所以樞紐不是某個 loop，而是先把 **trace 標準化**。先講這個基座。

---

## 3. Part 0 — Run Trace 基座（keystone）

### 3.1 問題

今天一次 run 的證據是散的：`points/<slug>.md`、`handoffs/<slug>-*.md`、git commit、
retry 次數只活在 flow agent 腦裡。**沒有任何物件把「整次 run 作為一個結果」記下來**，
所以無法回看、無法統計、無法學習。而 handoff 散檔還會無限堆積（「太多檔案」）。

### 3.2 Run Trace schema

flow 在結束前，以 **flow-inline 步驟**（跟 post-build 一樣不開 agent，因為這些資料此刻全在
flow context 裡）序列化出一筆 trace：

```
.athena/traces/runs.jsonl        # append-only，一行一個 run，只會長不會爆
```

每筆骨架：

| 欄位 | 內容 |
|---|---|
| `run_id` / `slug` / `ts` | 識別 |
| `trigger` | `manual` / `ci` / `pr-review` / `cron` / `inbox`（source 類別，標記來源，供 2b/3；trigger name 另記 dispatcher state） |
| `point` | verdict + score + 各 dimension 分數 |
| `weight` / `route` | Minimal / Lightweight / Full + 實走路線 |
| `stages[]` | 每 stage：skill 名、gate verdict、retry 次數、agent 數 |
| `failures[]` | **failure taxonomy tag** + affected_phase + 一行描述 |
| `human_interventions` | 使用者中途修正/否決次數 |
| `outcome` | `shipped` / `stopped@<stage>` / `handed-to-human` |

### 3.3 Failure Taxonomy（讓 3 能統計，而非讀自由文字）

```
spec-gap | plan-gap | skill-defect | contract-violation |
integration-mismatch | flaky | scope-underestimate | scope-overestimate | env
```

> 這是唯一需要動到核心契約的地方：`agent-handoff.md` 的 gate verdict 在 FAIL 時多帶一個
> taxonomy tag enum（你現在 verify-retry 已要求標 `affected_phase`，這只是再加一個欄位）。
> 改動極小，但讓 Loop 3 從「讀作文」變「跑統計」。

### 3.4 Handoff 生命週期與 GC

**重新定位**：handoff **不是歷史紀錄**，是 stage/phase 之間的**交接草稿（scratch）**——
任務一結束就沒用了。真正該留的歷史是 Run Trace。

emit-trace 步驟同時是 **GC 點**：

```
run 結束
  → emit trace（把 gate verdict / failure tag / files changed 蒸餾進 runs.jsonl）
  → 然後刪掉這個 slug 的 handoffs
```

**保留策略**（同時解決「太多檔案」與「Loop 3 要學失敗」）：

| run 結局 | handoffs 處置 | 理由 |
|---|---|---|
| `shipped` / `done`（乾淨完成） | **emit trace → 刪除** | 乾淨 run 無學習價值，trace 的 `gate=PASS` 一行就夠 |
| `stopped@stage` / `handed-to-human`（未解） | **保留** | (a) 下次靠它 resume；(b) Loop 3 學失敗的原料 |
| 失敗已解（重跑 ship，或 hill-climb 已折成 eval case） | 刪除 | 學完即回收 |

效果：**`handoffs/` 任何時刻只裝「進行中或未解」的 run，乾淨 by construction**。
GC 只刪「已有對應 `shipped` trace」的 run，**絕不刪 in-flight**。

掃尾保險（接 2b）：crash / 放棄的 run handoff 會殘留，讓 Trigger Dispatcher 多一個
housekeeping tick：「刪掉已有 shipped trace 且超過 X 天的 handoff」。

可選團隊 knob：`keep-failures-only`（預設）/ `keep-last-N` / `keep-all`。

---

## 4. Part 2b — 事件驅動觸發層（Trigger Dispatcher）

**目標**：flow 能被 CI 紅燈 / PR review comment / 部署狀態 / 排程自動啟動，而非只靠人打 `/flow`。

**純原生 = 輪詢即事件**。CC 原生沒有 webhook（hooks 只觀察 *Claude 自己的動作與 session
生命週期*，不是外部世界）。所以事件層 = 一個用 **`/loop`（自我節奏，靠 `ScheduleWakeup`
續跑）** 或 **cron routine（時間觸發）** 跑的**輪詢式 Dispatcher**。

### 4.1 Trigger Registry — `.athena/triggers.yml`

```yaml
triggers:
  - name: ci-red-on-pr
    source: ci            # 唯讀 `gh run list` / `gh pr checks`
    when: status == failed
    poll: 270s            # CI 活躍時 <5min 保持 cache 溫；閒置拉到 20–30min
    intake: fix           # 把失敗 log 包成 bug 餵 point
    autonomy: notify      # notify | auto-to-gate | auto-full
    guard: branch matches feature/*

  - name: review-changes-requested
    source: pr-review
    when: review_state == changes_requested
    intake: address-review
    autonomy: auto-to-gate

  - name: nightly-retro
    source: cron
    when: "0 2 * * 1"     # 週一 02:00 → 觸發 Loop 3
    intake: hill-climb

  - name: external
    source: inbox         # 監看 .athena/inbox/ 有沒有新檔
    intake: from-file
```

### 4.2 Dispatcher 每 tick 做的事

1. 唯讀 CLI 評估各 trigger 的 source（`gh` 等）
2. 套 `guard` + `when`
3. **Dedup / debounce**：`.athena/triggers/state.json` 記「上次見過的 event id / 上次 dispatch」，
   同一個 CI failure 不重觸發
4. **Single-flight**：同一 slug/branch 已有 in-flight run 就不再起第二條
5. 命中 → **製造一個 intake**（CI 紅燈 = 一張 bug 單，含失敗 test + log 摘要）→ 呼叫 `/athena-flow`
6. 寫一筆 `trigger:` 標記的 trace

### 4.3 三個必須講清楚的設計決策

- **事件層不繞過 point**：只是「自動生成 intake」，仍走 point 評分分流。CI 紅燈通常 →
  `PASS-TRIVIAL`/`DIRECT-BUILD`（快修路線）。維持「所有東西都過 point」的單一真相。
- **Autonomy gate（安全核心）**：自動起一條會改 code 的 flow 很危險，預設 **`notify`**
  （用 `PushNotification`/task 問「要不要起 fix flow？」）；信任類別才 `auto-to-gate`
  （自動跑但**停在 ship 前**，絕不自動 push）；`auto-full` 要顯式開。
- **Inbox 縫合（純原生但 webhook-ready）**：`source: inbox` 監看 `.athena/inbox/` 檔案佇列。
  今天人/本地腳本丟檔；哪天想接 GitHub Action webhook，Action 只要把事件寫進 inbox，
  dispatcher 完全不用改。

**誠實限制**：純原生 = 輪詢，延遲 = poll 間隔（非即時 push）。這是選「純原生」的內建代價，
上面 inbox 縫讓日後可零成本升級到 push。

---

## 5. Part 3 — 自我改進圈（Hill-Climb / Retro 技能）

**目標**：讀 trace → 找**系統性**模式 → 對 skill / rubric / prompt / contract / memory 提改進
→ **人工 gate 採納** → 量測是否真的爬上山。

新技能 `athena-hill-climb`（由 `nightly-retro` trigger 或「累積 N 筆新 trace」門檻觸發——
所以 **2b 最有價值的客戶就是 3**）。六步：

1. **Collect**：從 `runs.jsonl` 讀上次 watermark 之後的 run（watermark 存
   `.athena/hill-climb/state.json`），按 taxonomy / stage / skill / phase 邊界聚合。

2. **Diagnose**：只挑**重複出現**的系統問題，每條附 trace 證據（run_ids）。例：
   > `integration-mismatch` 在 9 條 Full run 命中 4 條，全在 05↔06 endpoint 命名
   > → build skill 沒把 api.yml 當權威。

3. **Propose**：映射到**具體系統改動 + 目標物件**：

   | 失敗模式（重複） | 改進目標 | 改動 |
   |---|---|---|
   | integration-mismatch | build skill / api-spec 契約 | 加「以 api.yml 為 endpoint 權威」步驟 |
   | scope-underestimate | **point rubric** | 調 dimension 權重 / 加 override 關鍵字 |
   | contract-violation | stage contract / handoff 模板 | 收緊必填欄位 + validator |
   | skill-defect | team skill | 立 eval case + 修 |
   | flaky | verify / smoke | quarantine、標 xfail 並寫移除條件 |

4. **Verify 改進（閉環關鍵 — 復活孤兒工具）**：
   - skill 類 → **trace 本身就是現成 regression eval case**（有 intake=輸入、expected=本該如何、
     actual=怎麼壞），餵給既有 `athena-skill-eval` 真跑驗證。
   - rubric 類 → 拿 trace 裡歷史 intake **重新 point 一次**，看 verdict 分布有否改善。
   - contract 類 → 既有 `athena-skill-audit` 靜態檢查。

   > 這一步把現在**靜態、與 flow 脫鉤**的 `skill-audit`/`skill-eval` 接成 hill-climbing 的
   > 「改完有沒有比較好」測量臂——從「手動體檢工具」變「自我改進圈的測量儀」。

5. **Apply — 一律人工 gate**：hill-climb **絕不自動改 skill/rubric**，只吐
   `.athena/hill-climb/<date>-proposals.md`（沿用 ✅/🟡/💡 格式，不用 PASS/FAIL 以免被當 CI gate）。
   被採納的提案本身變成一張 `/flow` intake——**系統用自己改進自己（dogfooding）**。

6. **Measure（hill-climbing 的「hill」）**：`.athena/hill-climb/metrics.jsonl` 追蹤少數
   flow-health 指標隨時間變化：gate 一次過率、verify-retry 率、scope 準確率
   （point verdict vs 實際是否 escalate）、平均 agents/run、人工介入率。
   **沒有指標的「自我改進」只是感覺。** Retro 報告秀趨勢線。

---

## 6. 三圈如何組合（閉環全圖）

```
  Loop 3        ┌──────────────────────────────────────────────┐
  自我改進       │ Hill-Climb（retro skill，排程/門檻觸發）         │
               │ traces → diagnose → propose → eval/audit → 🧑   │
               └──────▲ 讀 traces ───────────┬─ proposals→intake ┘
                      │                       │
  Loop 2b      ┌──────┴───────────────────────▼──────────────────┐
  事件驅動       │ Trigger Dispatcher（/loop 輪詢 + dedup + autonomy）│
  (intake)     │ ci / pr-review / cron / inbox → 製造 intake → /flow│
               └──────────────────┬───────────────────────────────┘
                                  │ intake
  Loop 2a + 1   ┌─────────────────▼────────────────────────────────┐
  (既有核心)     │ /flow: point → stages → gates → verify-retry       │
               │        每個 stage = agent loop (Loop 1)             │
               │        每次 run ──── EMIT Run Trace + GC handoffs ───┼─┐
               └──────────────────────────────────────────────────┘ │
                                  └──── .athena/traces/ ◄────────────┘
```

樞紐是 **Run Trace**：2b 餵進會 emit trace 的同一條管線；3 消費 trace、吐出的提案又以 intake
重新進場。系統閉環。

---

## 7. 落地計畫：基座 → 2b → 3（順序被資料需求逼出來）

**Step 1 — Run Trace 基座（含 handoff GC）。一定第一個，且單獨做。**
- 它是依賴：2b 要 emit trace、3 要讀 trace，兩外圈都掛它上面。
- 它當天還價值：GC 那半直接解決「太多檔案」。
- 它一上線就蓄水：之後每次 `/flow`（含蓋 2b/3 的 run）都往 trace lake 丟資料。
- 注意：GC 跟 trace **必須一起出**——先有 trace 蒸餾出該留的，刪 handoff 才安全。

**Step 2 — Loop 2b（事件驅動），不是 3。**
- 3 不能排第二：基座剛上線 trace 近乎空，這時蓋 3 = 對空湖 hill-climbing。
- 2b 相反：馬上能交付，且每觸發一次就多餵一筆 trace 給 3 —— 它主動加速 3 需要的 corpus。
- 2b 先只開最安全形態 `autonomy: notify`，把 dedup / single-flight 驗穩再放寬。

**Step 3 — Loop 3（自我改進），最後，且「等資料到位才開工」。**
- 觸發「現在可蓋 3」的訊號是**資料量**不是日曆——約 15~30 條真實 run、含幾條真失敗時才有得爬。

一句話：**3 必須最後，不是因為排在後面，而是因為要等 trace 長出來；2b 卡中間，
因為它一邊交付價值一邊替 3 養資料。**

---

## 8. plugin 具體改動清單

> 真正寫 code 依 repo 非協商規則先走 `/athena-point`；以下只列 scope。

**① 基座（Step 1，先做）**
- 新 `skills/athena-flow/references/run-trace.md`（schema + failure taxonomy + handoff retention policy）
- 改 `athena-flow/SKILL.md`：收尾加 flow-inline「emit trace + GC handoffs」步驟
- 改 `agent-handoff.md`：gate verdict FAIL 多帶 taxonomy tag enum

**② Loop 2b（Step 2）**
- 新技能 `athena-trigger-dispatch`（`/loop` dispatcher）
- 新 `references/event-triggers.md`（sources / dedup / autonomy / 輪詢 cache 節奏 / single-flight）
- `.athena/triggers.yml` schema + `.athena/inbox/` 約定

**③ Loop 3（Step 3）**
- 新技能 `athena-hill-climb`（retro，整合既有 skill-eval / skill-audit 當驗證臂）
- 新 `references/hill-climb.md`（六步 + metrics schema）
- `.athena/hill-climb/`（state / proposals / metrics）

---

## 9. 跨圈非協商規則

1. **事件層不繞過 point** — 一律製造 intake 走分流。
2. **預設 `notify`，會改 code 的自動觸發必須停在 ship 前** — 絕不自動 push。
3. **Dispatcher 必須 dedup + single-flight** — 同事件不重觸發、同 branch 不併發。
4. **輪詢要 cache-aware** — 活躍 <5min（270s）、閒置 20–30min，別固定 300s。
5. **Hill-climb 不自動改系統** — 只出提案，採納走 `/flow`（dogfooding）。
6. **沒有 metric 不算改進** — 每次 retro 要能對照趨勢。
7. **Handoff 是 ephemeral，trace 是 durable** — 乾淨完成的 run 必須在 emit trace 後刪除其
   handoffs；只有未解 / 失敗待學的 run 才保留。GC 只刪「已有 shipped trace」的 run，
   絕不刪 in-flight。

---

## 10. 風險與限制

- **純原生 = 輪詢非 push**：事件延遲 = poll 間隔。inbox 縫保留日後升級到 push 的零成本路徑。
- **Autonomy 誤觸發**：2b 自動起 flow 若 dedup/guard 有 bug 會洗版或誤改 code。預設 notify + single-flight 是主要護欄。
- **Trace 隱私/體積**：`runs.jsonl` append-only 會長，但一行一 run、且 gitignore（runtime artifact）。需要時加 rotate（按月分檔）。
- **Hill-climb 過擬合**：對少量 trace 過度推論。靠「只挑重複出現」+ metric 趨勢防止。
- **plugin 自身 dogfood 限制**：此 repo `.athena/skills/` 無完整 standard stage skill，
  跑不了完整 `/flow`，只能驗 point + harness 機制；完整三圈驗證需在 consumer 專案。
</content>
</invoke>
