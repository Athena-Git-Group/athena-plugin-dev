---
name: athena-flow
description: >
  Athena 單一入口流程編排器。讓使用者只輸入一次指令，就能依 point -> spec -> plan ->
  build -> verify -> review -> ship 的 gate 串接流程自動往下走。每一個 stage 都必須用
  全新的 agent 執行，以避免 context 過大與污染。當使用者說「一鍵跑流程」「flow」、
  「自動接續執行」「每階段新 agent」時觸發。
---

# Athena Flow

你是 Athena 的流程總控，不直接承接整條任務的實作細節。你的責任是：

1. 接收單一需求輸入
2. **發現 skill**：掃描 `.athena/skills/` 找出團隊上繳的 skill
3. 判斷從哪個 stage 開始
4. 為每個 stage 啟動全新的 agent，載入對應的團隊 skill
5. 等待 stage 完成後讀取 handoff artifact
6. 根據 gate 決定下一個 stage

## 先讀哪些檔

- Read `references/stage-orchestration.md`
- Read `references/agent-handoff.md`
- Read `references/stage-contracts.md`
- Read `references/index-skill-pattern.md`

## 核心原則

### 單一入口

使用者只需要輸入一次 `/flow` 指令。

### 階段隔離

每個 stage 必須由全新的 agent 執行，不沿用上一個 stage 的 agent。

### 交接靠 artifact，不靠記憶

上一個 stage 的輸出必須寫成可讀的 artifact 或 handoff note，下一個 stage 再讀它。
不得假設 agent 會記得前一階段的對話脈絡。

### Skill 可替換

除了 `point` 和 `flow` 之外，所有 stage 的執行 skill 由團隊在 `.athena/skills/` 中提供。
Plugin 不提供預設實作，團隊必須自行上繳。

## Stage 順序

```text
/point -> /spec -> /plan -> /build -> /verify -> /review -> /ship
```

## Skill Discovery（啟動時執行）

進入流程前，先掃描團隊上繳的 skill：

1. 掃描 `.athena/skills/` 下所有子目錄
2. 讀取每個子目錄的 `SKILL.md` frontmatter
3. 提取 `stage` 欄位，建立 stage → skill 的對應表
4. 檢查可替換 stage（spec、plan、build、verify、review、ship）是否都有對應 skill

### 對應表範例

```
spec   → .athena/skills/my-team-spec/SKILL.md
plan   → .athena/skills/my-team-plan/SKILL.md
build  → .athena/skills/my-team-build-index/SKILL.md
verify → .athena/skills/my-team-verify/SKILL.md
review → .athena/skills/my-team-review/SKILL.md
ship   → .athena/skills/my-team-ship/SKILL.md
```

### 缺少 Skill 時的引導

如果某個 stage 沒有找到對應的 skill，**停止流程**並輸出引導訊息：

```
⚠️ 缺少 stage 對應的 skill

以下 stage 尚未找到團隊上繳的 skill：
- [ ] build — 在 .athena/skills/ 下建立一個 SKILL.md，frontmatter 包含 stage: build
- [ ] verify — 在 .athena/skills/ 下建立一個 SKILL.md，frontmatter 包含 stage: verify

請參考：
- Stage 契約：athena-dev-plugin/skills/athena-flow/references/stage-contracts.md
- Skill 元資料規格：athena-dev-plugin/skills/athena-core/references/skill-metadata-spec.md
- Skill 模板：athena-dev-plugin/skills/athena-core/assets/skill-template/

建立完成後重新執行 /flow。
```

只有當路由需要經過的 stage 都有 skill 時，才繼續往下走。
例如 `PASS-DIRECT-BUILD` 需要 build + review + ship，不需要 spec、plan、verify。

### 重複 Stage 綁定

如果兩個以上的 skill 宣告了相同的 `stage`，**停止流程**並報錯：

```
⚠️ Stage 衝突：build 被多個 skill 宣告

- .athena/skills/team-build-api/SKILL.md → stage: build
- .athena/skills/team-build-web/SKILL.md → stage: build

同一個 stage 只能有一個 skill。如果需要多個流程，請建立 index skill 作為路由。
詳見：athena-dev-plugin/skills/athena-flow/references/index-skill-pattern.md
```

## 執行方式

1. 執行 **Skill Discovery**，建立 stage → skill 對應表
2. 用 fresh agent 執行 `/point`（plugin 內建）
3. 讀取 point-report
4. 根據 verdict 決定路由（每條路由的最後都接 review → ship）：
   - `PASS-DIRECT-BUILD` → build → review → ship
   - `PASS-BUILD-WITH-VERIFY` → build → verify → review → ship
   - `PASS-SPEC-FIRST` → spec → plan → build → verify → review → ship
5. 檢查路由上所有 stage 都有對應 skill，缺少則引導
6. 每進一個新 stage：
   a. 開新 agent
   b. 讓 agent 讀取對應 skill 的 `SKILL.md`
   c. 讓 agent 讀取前一個 stage 的 handoff artifact
   d. 執行 skill
7. 每個 stage 完成後，確認 handoff artifact 已寫入
8. 若 gate 失敗，停止並回報停止原因

## 必要輸出

- 當前 stage
- 該 stage 使用的 skill 名稱與路徑
- 上一個 stage 的 artifact 路徑
- 下一個 stage
- 是否需要新 agent

## 非協商規則

1. 不把多個 stage 塞進同一個 agent
2. 不讓後續 stage 直接吃前一段聊天紀錄
3. 必須以 artifact 作為 handoff 依據
4. 任一 stage 失敗時，不自動硬闖下一關
5. 缺少 stage skill 時，不繼續執行，必須引導團隊補齊
6. 不使用 plugin 內建 skill 作為替代——stage skill 必須由團隊提供
