# Discovery sourcing report

> Plan package：`001-會員中心雙管道註冊登入`
> Source PRD：`會員中心雙管道註冊登入 PRD` v1.7（2026-04-21）
> `${PROJECT_SPEC_LANGUAGE}` = `zh-hant`，slug 一律以繁體中文撰寫；技術 token（OTP、check-contact-identity、MemberAuth、Customer、Captcha、Face ID、Keychain、Keystore、`+886`、SMS、Email、CRM、API、JWT、SOP、uuid、token）保留英文原文。

## Impact scope

- 本輪問題一句：把會員中心註冊／登入從「只支援 Email」擴成「Email 或台灣手機號碼」二擇一（統一輸入欄位自動識別），並補齊綁定、編輯、解除、忘記密碼、OTP 登入、App 生物辨識登入、刪除帳戶等周邊行為。
- 納入範圍：雙管道註冊、雙管道登入（密碼 + OTP + App 生物辨識）、首次帳號綁定（BIND）、補綁、編輯已綁定聯絡方式、解除綁定、手機忘記密碼、check-contact-identity 擴充、防重複帳號規則、刪除帳戶。
- 明確排除：第三方社群登入（LINE / Google 等）、Web 端生物辨識登入、CRM 後台手動建立會員流程。

## Function package charters

### `packages/01-雙管道註冊`

- **職責一句**：以統一輸入欄位識別 Email 或台灣手機號碼，完成會員中心帳號建立（含 SMS OTP 驗證、防重複帳號路由）。
- **納入**：手機註冊（含 SMS OTP）、Email 註冊、防重複帳號判定（LOGIN/BIND/NEW 結果由註冊端解讀後反映到回應）、密碼最小長度規則、手機號碼前端正規化、Captcha 保留。
- **排除**：登入第一階段識別（屬 02-雙管道登入）、首次綁定的密碼設定流程（屬 03-帳號綁定）、忘記密碼。
- **本輪變更型態**：`new-package`
- **本輪規格增量**：新增 sign-up/mobile、sign-up/mail、verify-otp 註冊路徑相關規格；對應 T-01~T-20 接受案例與 BR-01~BR-07 / BR-16~BR-19 / BR-25~BR-29 / BR-31 / BR-35~BR-37。

### `packages/02-雙管道登入`

- **職責一句**：以統一輸入欄位完成兩階段登入（先 check-contact-identity 識別 → 再驗密碼或 OTP），並承載 App 生物辨識快速登入。
- **納入**：check-contact-identity（NEW/BIND/LOGIN 三態）、密碼登入、OTP 驗證碼登入（Email + SMS）、App 生物辨識啟用／快速登入／停用、記住我（支援手機原始輸入）、Captcha。
- **排除**：註冊（屬 01）、首次帳號綁定動作（屬 03，由 BIND 結果路由過去）、忘記密碼（屬 05）、刪除帳戶（屬 06）。
- **本輪變更型態**：`new-package`
- **本輪規格增量**：新增 check-contact-identity 預檢、密碼登入、OTP 登入（Email/SMS）、App 生物辨識啟用／登入／停用；對應 T-21~T-34、T-106~T-126 接受案例與 BR-08~BR-10、BR-30、BR-32~BR-34、BR-51~BR-62。

### `packages/03-帳號綁定`

- **職責一句**：在 CRM 已有 Customer 但無 MemberAuth 時，把既有 Customer/Member 與新建會員中心帳號綁定（首次綁定 BIND 入口），以及已登入狀態下補綁另一種聯絡方式。
- **納入**：首次綁定（check-contact-identity = BIND 後設定密碼／手機 OTP 後建立 MemberAuth + MemberCenterProfile，沿用既有 Customer + Member）；補綁 Email/手機；綁定唯一性檢查；綁定後雙管道登入啟用；CRM 同一 Customer 之 Email 與手機並存判定。
- **排除**：純註冊（屬 01）、編輯／解除綁定（屬 04）、登入第一階段識別本身（屬 02）。
- **本輪變更型態**：`new-package`
- **本輪規格增量**：新增首次綁定 + 補綁規格；對應 T-35~T-43 接受案例與 BR-11~BR-19、BR-25~BR-26。

### `packages/04-編輯與解除綁定`

- **職責一句**：在帳號設定頁面修改已綁定 Email/手機（編輯）或移除其中一種綁定（解除），維持「至少一種綁定」前提。
- **納入**：編輯 Email（不需 OTP）、編輯手機（SMS OTP 驗證）、編輯唯一性檢查、解除綁定（僅雙綁定可解除、不需密碼僅二次確認）、解除後登入影響、聯絡方式釋放。
- **排除**：首次綁定／補綁（屬 03）、註冊／登入流程本身。
- **本輪變更型態**：`new-package`
- **本輪規格增量**：新增編輯 + 解除綁定規格；對應 T-90~T-105 接受案例與 BR-44~BR-50。

### `packages/05-忘記密碼`

- **職責一句**：提供兩種忘記密碼流程——Email 沿用現有重設、手機透過 SMS OTP 驗證後重設。
- **納入**：Email 忘記密碼（直接重設）、手機忘記密碼（SMS OTP → verify-otp → forgot/reset）、OTP 頻率與每日上限規則、OTP 用途不互通（FORGOT_PASSWORD ≠ REGISTER/LOGIN）。
- **排除**：OTP 登入（屬 02）、註冊／綁定流程內的 OTP（屬 01/03）。
- **本輪變更型態**：`new-package`
- **本輪規格增量**：新增 forgot/mail、forgot/mobile、forgot/reset 相關規格；對應 T-44~T-51 接受案例與 BR-20~BR-24、BR-52、BR-58（OTP 用途不互通）、BR-36（後端錯誤限制）。

### `packages/06-刪除帳戶`

- **職責一句**：使用者主動以密碼確認後軟刪除會員中心帳號（MemberAuth），保留 CRM Customer 資料。
- **納入**：刪除帳戶警告與二次確認、密碼驗證、軟刪除 MemberAuth、清除前端 token、原綁定聯絡方式可重新註冊（check-contact-identity 回 NEW）。
- **排除**：CRM Customer 資料的後台處理（不在會員中心 boundary 內）、帳號停權 / 凍結等其他狀態。
- **本輪變更型態**：`new-package`
- **本輪規格增量**：新增 delete-account API 規格；對應 T-80~T-89 接受案例與 BR-38~BR-43。

## Packaging decision

- 新 plan package：`001-會員中心雙管道註冊登入`
- 本輪涉及的 function packages：
  - `packages/01-雙管道註冊`（新開）
  - `packages/02-雙管道登入`（新開）
  - `packages/03-帳號綁定`（新開）
  - `packages/04-編輯與解除綁定`（新開）
  - `packages/05-忘記密碼`（新開）
  - `packages/06-刪除帳戶`（新開）
- function package 決策：本輪為 greenfield 新需求，需同時新開 plan package 與 6 個 function package。包顆粒度依「單一對外入口／狀態所有權／變更爆炸半徑」三題拆解：6 包各自擁有可獨立講完的對外行為主線與狀態生命週期，改一包不應強迫連坐改其他包（編輯／解除與綁定切分為兩包是因為「補綁」屬於把新聯絡方式加入既有帳號，「編輯／解除」則是已綁狀態下的維護動作，狀態所有權不同）。check-contact-identity 雖被多包共用，但其主入口被「02-雙管道登入」第一階段擁有，由其他包以對 API 規格 read_only_compare 對照。

## Resolved sourcing decisions（已拍板）

- 登入是否維持兩階段：**是**（v1.2 Q-01）；統一輸入框後第一階段仍呼叫 check-contact-identity，第二階段顯示密碼。
- 註冊是否走 check-contact-identity：**否**（v1.2 Q-05 / BR-35）；註冊直接提交帳號密碼至後端，後端回成功或失敗（含錯誤訊息）。
- 統一欄位識別觸發時機：**blur**（v1.2 Q-04 / BR-30）；避免輸入過程中 UI 閃爍。
- OTP 錯誤次數上限／IP 限制／SMS 廠商：**由 Java 後端處理**（v1.2 Q-06/08/09 / BR-36~BR-37）；前端僅顯示後端回傳 error code / error msg。
- otpToken 設計：**沿用既有 uuid**（v1.2 Q-07）；不另設 JWT。
- 忘記密碼國碼選擇器：**移除**（v1.2 Q-10）；與註冊／登入一致使用統一欄位。
- Captcha：**註冊／登入／忘記密碼均保留**（v1.2 Q-11 / BR-31）。
- 「記住我」記住格式：**使用者原始輸入**（如 `0912345678`）（v1.2 Q-12 / BR-32）。
- 錯誤訊息：**後端回什麼就直接顯示**（v1.2 Q-13 / BR-33）；前端不做 i18n。
- 解除綁定身份驗證強度（v1.7 更新）：**僅需二次確認彈窗，不需密碼**（BR-48）。
- check-contact-identity 主入口歸屬：**`packages/02-雙管道登入`**；註冊與綁定包對該 API 規格採 read-only 對照。

## Notes

- Boundary truth 掃描範圍（`specs/contracts/`、`specs/data/`、`specs/packages/`、`specs/shared/dsl.yml`）目前皆為 greenfield 空集合；無既有契約／資料可對照，所有 truth 將於後續 phase（`/aibdd-form-api-spec`、`/aibdd-form-entity-spec` 等）建立。
- `${IMPACT_MATRIX_YML}` 結束時包含 26 筆 `add` entries，對應 6 packages 下的全部 feature files。validate.ok=true。
- Plan-side artifacts（`reports/discovery-sourcing.md`、`spec.md`、`reports/impact-matrix.yml` 本身）不放進 impact-matrix entries。
- `Function package charters` 與 `Packaging decision` 互相一致：本輪 6 包全為 `new-package`。

## Clarify outcomes（sub-SOP 03 step 2-4）

| # | 切角 | 位置 | 拍板決議 |
|---|------|------|----------|
| CLARIFY-01 | 證據不足 | `03-帳號綁定/.../01-首次綁定Email建立帳號.feature` | **需要兩次輸入比對**；UI「密碼」+「密碼確認」兩欄位，前後端皆驗證一致 |
| CLARIFY-02 | 時序或狀態轉移不清 | `02-雙管道登入/.../03-OTP登入發送驗證碼.feature` | **不能在第一階段直接走 OTP**；必須先進第二階段密碼頁後點擊「改用驗證碼登入」 |
| CLARIFY-03 | 結果面向缺口 | `02-雙管道登入/.../06-App生物辨識登入.feature` | **被動發現**；維持現行 rule，密碼變更後其他裝置 token 失效僅在下次登入時提示「請重新登入」，不主動 push 通知 |
| CLARIFY-04 | 結果面向缺口 | `04-編輯與解除綁定/.../{01-編輯Email,03-編輯手機完成更新}.feature` | **只送「新」聯絡方式**（確認可接收）；舊聯絡方式不寄變更通知 |
| CLARIFY-05 | 規則疊加後缺少合成規則 | `01-雙管道註冊/.../03-手機註冊完成驗證.feature` | **顯示遮罩過的既有 Email**（與 T-75/T-76 隱碼規則一致），讓使用者確認身份再導向綁定 |
| CLARIFY-06 | 結果面向缺口 | `06-刪除帳戶/.../01-刪除帳戶.feature` | **一併撤銷**；刪除帳戶時後端撤銷該帳號於所有 App 端裝置之 refresh token，採與 BR-62 同一失效路徑 |

所有拍板決議已直接寫回對應 .feature 為新增 atomic rules（rule body 標記 `CLARIFY-XX 已確認`），亦同步於本報告留存以便 reconcile。
