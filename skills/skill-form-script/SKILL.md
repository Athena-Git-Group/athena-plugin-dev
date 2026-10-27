---
name: skill-form-script
description: 撰寫 skill 之 scripts/ 底下 Python 腳本時，必須使用此 skill。
---

# SOP

## Phase 1 -- 讀取目標

1. READ 讀取目標 Python script 內容，確認要新增、修改或重寫的腳本範圍。

## Phase 2 -- 按需思考並完成

1. THINK 在思考 script 結構、相依宣告、執行方式與輸入輸出時，按需讀取 `rules/Python-單檔腳本格式.md` 與 `rules/跨平台執行與依賴處理.md`；只在需要判斷 `PEP 723` metadata、CLI 介面、錯誤提示或依賴處理方式時才載入，並依實際讀取到的規則收斂最小可用腳本。
2. WRITE 依思考結果撰寫或修改目標 Python script。
3. READ 回頭檢查結果是否符合本次實際載入的規則；若不符合，立即修正。
