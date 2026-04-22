# Knowledge Base Guidelines

當需求不只是技術描述，而是帶有產品規則主張時，先把知識庫視為真相候選來源。

## 什麼時候要讀知識庫

- 使用者只提供一句規則判斷，例如「使用者應該可以 X，不應該可以 Y」
- PM ticket 提到「依照既有規格」
- 需求牽涉例外條件、角色差異、業務名詞
- 團隊對「正確行為」可能沒有共享理解

## 建議讀取順序

1. PM ticket / issue 本身的 acceptance criteria
2. 產品規格文件
3. 知識庫 / SOP / policy
4. 既有類似功能的實作與測試

## 讀完後要修正什麼

- Requirement Clarity 分數
- Domain Rule Complexity 分數
- Knowledge Dependency 分數
- 最終 route

## 若找不到知識來源

不要假設規則正確。提高：

- Requirement Clarity
- Knowledge Dependency

並將結果升級成 `Spec First` 或至少 `Build With Verify`。
