# Knowledge Base Guidelines

當需求不只是技術描述，而是帶有產品規則主張時，先把知識庫視為真相候選來源。

## 知識庫位置

團隊的知識庫統一放在專案根目錄的 `.athena/knowledge/` 下。

```
.athena/knowledge/
├── domain-rules/        # 業務規則、政策、SOP
├── product-specs/       # 產品規格、PRD、功能定義
├── api-contracts/       # API 規格、schema 定義
└── ...                  # 團隊自由組織子目錄
```

目錄結構由團隊自行組織，沒有強制規範。建議用語意化的子目錄分類。

## 什麼時候要讀知識庫

- 使用者只提供一句規則判斷，例如「使用者應該可以 X，不應該可以 Y」
- PM ticket 提到「依照既有規格」
- 需求牽涉例外條件、角色差異、業務名詞
- 團隊對「正確行為」可能沒有共享理解

## 讀取流程

1. **掃描目錄**：先列出 `.athena/knowledge/` 的目錄結構，掌握有哪些知識文件
2. **關鍵字比對**：根據需求中的關鍵詞（業務名詞、功能名稱、角色、流程名）找出可能相關的文件
3. **讀取相關文件**：讀取匹配到的知識文件
4. **交叉驗證**：用知識庫內容驗證需求中的規則主張是否正確

## 建議讀取優先順序

1. PM ticket / issue 本身的 acceptance criteria
2. `.athena/knowledge/` 中與需求直接相關的文件
3. 既有類似功能的實作與測試

## 讀完後要修正什麼

- Requirement Clarity 分數
- Domain Rule Complexity 分數
- Knowledge Dependency 分數
- 最終 route

## 若 `.athena/knowledge/` 不存在或為空

不影響評分流程。Knowledge Dependency 維度照常評分：

- 若需求明顯依賴知識庫但團隊尚未建立 → 提高 Knowledge Dependency 分數
- 建議團隊建立 `.athena/knowledge/` 並放入相關文件

## 若找不到相關知識來源

不要假設規則正確。提高：

- Requirement Clarity
- Knowledge Dependency

並將結果升級成 `Spec First` 或至少 `Build With Verify`。

## Point Report 中的知識庫引用

在 point-report 中必須記錄：

- `Knowledge base needed: yes/no`
- `Knowledge sources consulted:` 列出實際讀取的檔案路徑（相對於 `.athena/knowledge/`）
- 若判斷需要但找不到 → 明確標註「需要但未找到」
