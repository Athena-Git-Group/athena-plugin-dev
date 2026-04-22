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
2. 判斷從哪個 stage 開始
3. 為每個 stage 啟動全新的 agent
4. 等待 stage 完成後讀取 handoff artifact
5. 根據 gate 決定下一個 stage

## 先讀哪些檔

- Read `references/stage-orchestration.md`
- Read `references/agent-handoff.md`

## 核心原則

### 單一入口

使用者只需要輸入一次 `/flow` 指令。

### 階段隔離

每個 stage 必須由全新的 agent 執行，不沿用上一個 stage 的 agent。

### 交接靠 artifact，不靠記憶

上一個 stage 的輸出必須寫成可讀的 artifact 或 handoff note，下一個 stage 再讀它。
不得假設 agent 會記得前一階段的對話脈絡。

## Stage 順序

```text
/point -> /spec -> /plan -> /build-backend or /build-frontend -> /verify -> /review -> /ship
```

## 執行方式

1. 用 fresh agent 執行 `/point`
2. 讀取 point-report
3. 根據 verdict 決定：
   - `PASS-DIRECT-BUILD` -> build
   - `PASS-BUILD-WITH-VERIFY` -> build -> verify
   - `PASS-SPEC-FIRST` -> spec -> plan -> build
4. 每進一個新 stage，都重新開新 agent
5. 每個 stage 完成後都寫入 handoff artifact
6. 若 gate 失敗，停止並回報停止原因

## 必要輸出

- 當前 stage
- 上一個 stage 的 artifact 路徑
- 下一個 stage
- 是否需要新 agent

## 非協商規則

1. 不把多個 stage 塞進同一個 agent
2. 不讓後續 stage 直接吃前一段聊天紀錄
3. 必須以 artifact 作為 handoff 依據
4. 任一 stage 失敗時，不自動硬闖下一關
