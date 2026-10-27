---
name: artifact-to-skill-engineering
description: 將「給定 artifact 範例，逐步定稿 example、反向抽取 template，再以此 artifact 反推 target skill」的工作方法固化成可重複執行的編排 skill。會先判斷目前位於 example 選定、example 定稿、template 抽取、skill engineering 或最終驗證哪個階段，再依 gate 決定下一步；只有在高影響歧義會改變 artifact 結構、欄位語意或後續 skill 設計時才升級 `/clarify`。預設保持最小 SOP，優先沿用 `/skill-form-template` 與 `/skill-engineering`，避免過度工程。
disable-model-invocation: true
---

# Artifact To Skill Engineering

把「先定稿 artifact example、再抽 template、最後反推 skill」這條鏈路編排成可反覆重用的工程流程。此 skill 的責任是掌控順序、gate 與 handoff，確保 example、template 與 target skill 維持單一溯源；它不取代 `/skill-form-template` 或 `/skill-engineering` 的專職工作。

# SOP

## Phase 1 -- 收斂參考 artifact、target skill 與目前階段

1. READ 讀取使用者需求、當前上下文、已存在的 artifact 檔案與目標 skill 目錄，確認本次要工程化的 artifact 主題、候選 example、target skill 名稱，以及目前是否已存在 template 或 target skill 草稿。
2. THINK 若需要判斷哪一份 example 才是主要參照物、目前卡在哪個階段，或是否已有前置產物可沿用，先讀取 `rules/參考範例選定與階段定位判準.md`，再收斂本次唯一主要 example、目標 skill 目錄與目前應停留的最早未完成階段。
3. WRITE 若主要參照 example、target skill 名稱，或目前階段仍無法唯一判定，向使用者提出最小必要確認並停止；未收斂前不得跳到後續階段。

## Phase 2 -- 互動式定稿 example

1. READ 讀取已選定的 example artifact 與其相鄰上下文，確認目前 example 的結構、欄位語意、內容粒度與使用者已要求的客製化方向。
2. THINK 若需要判斷 example 是否已可視為定稿、哪些差異應直接修改、哪些歧義應升級 `/clarify`，先讀取 `rules/範例定稿閘門與Clarify升級判準.md`，再收斂本輪最小必要改動、待確認點與是否仍有阻塞後續 template 抽取的高影響缺口。
3. WRITE 若 example 尚未定稿，直接修改 example 或提出本輪最小必要調整，向使用者說明這次改動與待確認點，並以使用者確認作為定稿閘門。
4. DELEGATE 若仍存在會改變 artifact 結構、欄位邊界、範圍定義或後續 template 抽取方式的高影響缺口，呼叫 `/clarify` 先收斂；未定稿前停止，不進入 template 抽取。

## Phase 3 -- 由 example 反向抽取 template

1. DELEGATE 若 example 已定稿且 template 雙檔尚未建立、需要重抽，或與最新 example 已不一致，呼叫 `/skill-form-template` 建立或更新 target skill `templates/` 下對應的骨架檔與範例檔。
2. THINK 若需要判斷 template 是否已足以作為後續 skill engineering 的目標 artifact，先讀取 `rules/模板抽取完成條件與進入SkillEngineering前置判準.md`，再檢查模板雙檔是否忠實反映已定稿 example、骨架與範例職責是否分離，以及後續不需再回頭大改 artifact 結構。
3. WRITE 若 template 尚未完成、仍與已定稿 example 不一致，向使用者說明缺口並停在此階段；未通過前置檢查前，不進入 skill engineering。

## Phase 4 -- 以 template / example 反推 target skill

1. DELEGATE 若 template / example 已穩定且 target skill 尚未完成，呼叫 `/skill-engineering` 以前述 artifact 為目標，規劃或落地 target skill 的最小 SOP 控制平面、必要 rules 與其他按需模組，並明示遵守「不要過度工程、先從最簡單 SOP 開始、規則必須確實掛回執行」。

## Phase 5 -- 驗證單一溯源並交付目前狀態

1. READ 回頭檢查主要 example、template 雙檔與 target skill 是否仍屬同一條單一溯源：example 先被定稿、template 由 example 抽出、target skill 以 template / example 作為目標 artifact，而非平行新增第二套規格。
2. WRITE 向使用者回報目前已完成的階段、仍未通過的 gate、已產生的 artifact / skill 路徑，以及下一個最合理動作；若 target skill 已落地完成，也要說明是在哪個 artifact 基礎上反推而成。
