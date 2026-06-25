# Sample PRD: 使用者註冊與個人資料查詢

> **用途**: athena-discovery 端到端驗證用 fixture。設計為**最小可觸發 3 種 Then handler 型態**的 PRD：
> - `aggregate-then`（驗 DB 屬性）
> - `success-failure`（只驗操作成敗 + 錯誤訊息）
> - `readmodel-then`（驗 Query response body）
>
> 同時涵蓋至少 3 條 Rule、至少 2 個 actor（一個外部使用者、一個第三方系統）。
> 不需要修改即可直接餵給 `/athena-discovery`。

## 背景

我們在做一個會員系統。使用者要能自己**註冊帳號**、之後也要能**查詢自己的個人資料**。

## 使用者期待

### 訪客（未註冊）

- 我提供 email 和 password，系統就建立我的帳號
- 如果我用的 email 已經被別人註冊過，我希望被告知「此 email 已被使用」而不是直接成功
- 註冊成功後系統會寄一封歡迎信給我（透過外部 email 服務）

### 已註冊使用者

- 我可以隨時查我自己的個人資料（email、註冊時間、上次登入時間）
- 我不能查別人的資料

## 業務規則（必須滿足）

| # | 規則 | 觸發 Handler |
|---|---|---|
| R1 | 註冊時 email 必須符合 RFC 5322 格式；不符合則拒絕 | success-failure |
| R2 | 註冊時 password 至少 8 字元；不符則拒絕 | success-failure |
| R3 | 註冊成功後，DB 中該 user 的 status 必須是 `active`、created_at 必須記錄 | aggregate-then |
| R4 | 註冊成功後，系統必須通知外部 email service 寄歡迎信（包含 user email 與 user_id）| aggregate-then（驗 outbound event）|
| R5 | 已註冊使用者查詢個人資料，回傳的 JSON 必須包含 email、registered_at、last_login_at | readmodel-then |
| R6 | 已註冊使用者不能查到其他人的資料；嘗試查他人 user_id 時回 404 | success-failure |

## Actors

- **訪客**（外部使用者，未持有 token）
- **已註冊使用者**（外部使用者，持有 valid token）
- **Email Service**（第三方系統，接收 outbound notification）

## Scope

- **In**: 註冊流程、個人資料查詢
- **Out**: 登入流程、密碼重設、社群登入、會員等級

## 不確定的點（給 discovery 練習 CiC）

- email 大小寫敏感嗎？例如 `Alice@Foo.com` vs `alice@foo.com` 算同一個帳號嗎？（**故意留模糊**——測 discovery 是否會貼便條紙）
- last_login_at 在剛註冊但還沒登入過的使用者上是 NULL 還是等於 registered_at？（**故意留模糊**）
