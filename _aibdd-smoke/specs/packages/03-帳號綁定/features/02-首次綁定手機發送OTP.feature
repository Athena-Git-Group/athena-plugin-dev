# @ignore - 等執行 /aibdd-red-execute 時，會只將 target Feature file 標注的 @ignore 拿掉，透過此手段來控制範疇。
@ignore
Feature: 為首次手機綁定發送 SMS OTP 驗證碼
    # Action：BIND 流程下使用者輸入手機後，點擊「發送驗證碼」由後端發送 SMS OTP 至該手機號碼。
    # 來源：PRD §5.3、BR-13/17/23/36/37、T-16、T-36。

    Rule: 前置（參數） - 使用者必須提供已通過 check-contact-identity 回傳 BIND 的手機號碼
        - 格式必須為正規化後 `+886` + 9 位數字（BR-27、BR-29）。
        Scenario Outline: <參數名> = <無效值> 時 <操作> 失敗
          # @dsl
          # handler-candidate-kinds: state-builder | operation-invoke | time-control | external-stub
          # rule: 先讀 ${SKILL_HOME}/aibdd-core/assets/boundaries/web-service/dsl-arrangement-rules/shared-given-law.md 理解 shared arrangement 作為你的推理流程，再讀 ${SKILL_HOME}/aibdd-core/assets/boundaries/web-service/dsl-arrangement-rules/given-delta-precondition-param.md 補 `前置（參數）` 所需建構出的系統合法狀態。
          # candidates:
          #   - customers.state-builder
          #   - members.state-builder
          #   - member_center_profiles.state-builder
          #   - signUpByMail.operation-invoke
          #   - sendRegisterMobileOtp.operation-invoke
          #   - verifyOtpForRegister.operation-invoke
          #   - checkContactIdentity.operation-invoke
          #   - passwordLogin.operation-invoke
          #   - sendLoginOtp.operation-invoke
          #   - verifyLoginOtp.operation-invoke
          #   - enableBiometric.operation-invoke
          #   - biometricLogin.operation-invoke
          #   - disableBiometric.operation-invoke
          #   - firstTimeBindEmail.operation-invoke
          #   - sendFirstTimeBindMobileOtp.operation-invoke
          #   - firstTimeBindMobile.operation-invoke
          #   - addEmailBinding.operation-invoke
          #   - sendAddMobileBindingOtp.operation-invoke
          #   - addMobileBinding.operation-invoke
          #   - editEmailBinding.operation-invoke
          #   - removeEmailBinding.operation-invoke
          #   - editMobileBinding.operation-invoke
          #   - removeMobileBinding.operation-invoke
          #   - sendEditMobileOtp.operation-invoke
          #   - forgotPasswordByEmail.operation-invoke
          #   - sendForgotPasswordMobileOtp.operation-invoke
          #   - verifyForgotPasswordOtp.operation-invoke
          #   - resetForgottenPassword.operation-invoke
          #   - deleteAccount.operation-invoke
          #   - shared.time-control.now
          Given <dsl>
          When <dsl>
          Then 操作失敗，錯誤為 "<具體驗證錯誤訊息>"

          Examples:
            | 參數名   | 無效值   | 操作   | 具體驗證錯誤訊息   |
            | <參數名> | <無效值> | <操作> | <具體驗證錯誤訊息> |

    Rule: 前置（狀態） - 系統內必須恰好有一筆對應該手機的 Customer 紀錄且該 Customer 尚未綁定會員中心帳號
        - 不同人衝突時應另走資料衝突分支（BR-18）。
        Example: <主詞> 不滿足 <條件> 時 <操作> 失敗
          # @dsl
          # handler-candidate-kinds: state-builder | operation-invoke | time-control | external-stub
          # rule: 先讀 ${SKILL_HOME}/aibdd-core/assets/boundaries/web-service/dsl-arrangement-rules/shared-given-law.md 理解 shared arrangement 作為你的推理流程，再讀 ${SKILL_HOME}/aibdd-core/assets/boundaries/web-service/dsl-arrangement-rules/given-delta-precondition-state.md 補 `前置（狀態）` 所需建構出的系統合法狀態。
          # candidates:
          #   - customers.state-builder
          #   - members.state-builder
          #   - member_center_profiles.state-builder
          #   - signUpByMail.operation-invoke
          #   - sendRegisterMobileOtp.operation-invoke
          #   - verifyOtpForRegister.operation-invoke
          #   - checkContactIdentity.operation-invoke
          #   - passwordLogin.operation-invoke
          #   - sendLoginOtp.operation-invoke
          #   - verifyLoginOtp.operation-invoke
          #   - enableBiometric.operation-invoke
          #   - biometricLogin.operation-invoke
          #   - disableBiometric.operation-invoke
          #   - firstTimeBindEmail.operation-invoke
          #   - sendFirstTimeBindMobileOtp.operation-invoke
          #   - firstTimeBindMobile.operation-invoke
          #   - addEmailBinding.operation-invoke
          #   - sendAddMobileBindingOtp.operation-invoke
          #   - addMobileBinding.operation-invoke
          #   - editEmailBinding.operation-invoke
          #   - removeEmailBinding.operation-invoke
          #   - editMobileBinding.operation-invoke
          #   - removeMobileBinding.operation-invoke
          #   - sendEditMobileOtp.operation-invoke
          #   - forgotPasswordByEmail.operation-invoke
          #   - sendForgotPasswordMobileOtp.operation-invoke
          #   - verifyForgotPasswordOtp.operation-invoke
          #   - resetForgottenPassword.operation-invoke
          #   - deleteAccount.operation-invoke
          #   - shared.time-control.now
          Given <dsl>
          When <dsl>
          Then 操作失敗，錯誤為 "<具體錯誤訊息>"
          # @dsl
          # handler-candidate-kinds: state-verifier
          # rule: 先讀 ${SKILL_HOME}/aibdd-core/assets/boundaries/web-service/dsl-arrangement-rules/shared-then-failure-law.md 理解失敗情境下 Then 怎麼推理，再用其中 `前置（狀態）` 小節判斷這裡該怎麼驗證操作失敗後系統狀態沒有變動。
          # candidates:
          #   - customers.state-verifier
          #   - members.state-verifier
          #   - members_customer_id_to_customers_id.state-verifier
          #   - member_center_profiles.state-verifier
          #   - member_center_profiles_member_auth_id_link_member_auths_id.state-verifier
          #   - member_center_profiles_member_id_to_members_id.state-verifier
          And <dsl>

    Rule: 後置（狀態） - 後端應發送 SMS OTP 至該手機號碼
        - 透過 IT 服務簡訊架構發送（BR-37）。
        Example: <操作> 後 <狀態主詞> 變為 <新狀態>
          # @dsl
          # handler-candidate-kinds: state-builder | operation-invoke | time-control | external-stub
          # rule: 先讀 ${SKILL_HOME}/aibdd-core/assets/boundaries/web-service/dsl-arrangement-rules/shared-given-law.md 理解 shared arrangement 作為你的推理流程，再讀 ${SKILL_HOME}/aibdd-core/assets/boundaries/web-service/dsl-arrangement-rules/given-delta-postcondition-state.md 補 `後置（狀態）` 所需建構出的可量測初始狀態。
          # candidates:
          #   - customers.state-builder
          #   - members.state-builder
          #   - member_center_profiles.state-builder
          #   - signUpByMail.operation-invoke
          #   - sendRegisterMobileOtp.operation-invoke
          #   - verifyOtpForRegister.operation-invoke
          #   - checkContactIdentity.operation-invoke
          #   - passwordLogin.operation-invoke
          #   - sendLoginOtp.operation-invoke
          #   - verifyLoginOtp.operation-invoke
          #   - enableBiometric.operation-invoke
          #   - biometricLogin.operation-invoke
          #   - disableBiometric.operation-invoke
          #   - firstTimeBindEmail.operation-invoke
          #   - sendFirstTimeBindMobileOtp.operation-invoke
          #   - firstTimeBindMobile.operation-invoke
          #   - addEmailBinding.operation-invoke
          #   - sendAddMobileBindingOtp.operation-invoke
          #   - addMobileBinding.operation-invoke
          #   - editEmailBinding.operation-invoke
          #   - removeEmailBinding.operation-invoke
          #   - editMobileBinding.operation-invoke
          #   - removeMobileBinding.operation-invoke
          #   - sendEditMobileOtp.operation-invoke
          #   - forgotPasswordByEmail.operation-invoke
          #   - sendForgotPasswordMobileOtp.operation-invoke
          #   - verifyForgotPasswordOtp.operation-invoke
          #   - resetForgottenPassword.operation-invoke
          #   - deleteAccount.operation-invoke
          #   - shared.time-control.now
          Given <dsl>
          When <dsl>
          Then 操作成功
          # @dsl
          # handler-candidate-kinds: state-verifier
          # rule: 先讀 ${SKILL_HOME}/aibdd-core/assets/boundaries/web-service/dsl-arrangement-rules/shared-then-success-law.md 理解成功情境下 Then 怎麼推理，再用其中 `後置（狀態）` 小節判斷這裡該怎麼驗證操作成功後系統狀態已經改成預期結果。
          # candidates:
          #   - customers.state-verifier
          #   - members.state-verifier
          #   - members_customer_id_to_customers_id.state-verifier
          #   - member_center_profiles.state-verifier
          #   - member_center_profiles_member_auth_id_link_member_auths_id.state-verifier
          #   - member_center_profiles_member_id_to_members_id.state-verifier
          And <dsl>

    Rule: 後置（回應） - 發送成功應回傳 OTP uuid
        - otpToken 沿用既有 uuid 機制。
        Example: <操作> 後 <回應主詞> 為 <期望值>
          # @dsl
          # handler-candidate-kinds: state-builder | operation-invoke | time-control | external-stub
          # rule: 先讀 ${SKILL_HOME}/aibdd-core/assets/boundaries/web-service/dsl-arrangement-rules/shared-given-law.md 理解 shared arrangement 作為你的推理流程，再讀 ${SKILL_HOME}/aibdd-core/assets/boundaries/web-service/dsl-arrangement-rules/given-delta-postcondition-response.md 補 `後置（回應）` 所需建構出的系統合法狀態。
          # candidates:
          #   - customers.state-builder
          #   - members.state-builder
          #   - member_center_profiles.state-builder
          #   - signUpByMail.operation-invoke
          #   - sendRegisterMobileOtp.operation-invoke
          #   - verifyOtpForRegister.operation-invoke
          #   - checkContactIdentity.operation-invoke
          #   - passwordLogin.operation-invoke
          #   - sendLoginOtp.operation-invoke
          #   - verifyLoginOtp.operation-invoke
          #   - enableBiometric.operation-invoke
          #   - biometricLogin.operation-invoke
          #   - disableBiometric.operation-invoke
          #   - firstTimeBindEmail.operation-invoke
          #   - sendFirstTimeBindMobileOtp.operation-invoke
          #   - firstTimeBindMobile.operation-invoke
          #   - addEmailBinding.operation-invoke
          #   - sendAddMobileBindingOtp.operation-invoke
          #   - addMobileBinding.operation-invoke
          #   - editEmailBinding.operation-invoke
          #   - removeEmailBinding.operation-invoke
          #   - editMobileBinding.operation-invoke
          #   - removeMobileBinding.operation-invoke
          #   - sendEditMobileOtp.operation-invoke
          #   - forgotPasswordByEmail.operation-invoke
          #   - sendForgotPasswordMobileOtp.operation-invoke
          #   - verifyForgotPasswordOtp.operation-invoke
          #   - resetForgottenPassword.operation-invoke
          #   - deleteAccount.operation-invoke
          #   - shared.time-control.now
          Given <dsl>
          When <dsl>
          Then 操作成功
          # @dsl
          # handler-candidate-kinds: response-verifier
          # rule: 先讀 ${SKILL_HOME}/aibdd-core/assets/boundaries/web-service/dsl-arrangement-rules/shared-then-success-law.md 理解成功情境下 Then 怎麼推理，再用其中 `後置（回應）` 小節判斷這裡該怎麼驗證操作成功後回應內容符合預期。
          # candidates:
          And <dsl>

    Rule: 後置（回應） - 重送間隔內再次請求應拒絕並提示倒數秒數
        - 60 秒重送間隔（BR-23）。
        Example: <操作> 後 <回應主詞> 為 <期望值>
          # @dsl
          # handler-candidate-kinds: state-builder | operation-invoke | time-control | external-stub
          # rule: 先讀 ${SKILL_HOME}/aibdd-core/assets/boundaries/web-service/dsl-arrangement-rules/shared-given-law.md 理解 shared arrangement 作為你的推理流程，再讀 ${SKILL_HOME}/aibdd-core/assets/boundaries/web-service/dsl-arrangement-rules/given-delta-postcondition-response.md 補 `後置（回應）` 所需建構出的系統合法狀態。
          # candidates:
          #   - customers.state-builder
          #   - members.state-builder
          #   - member_center_profiles.state-builder
          #   - signUpByMail.operation-invoke
          #   - sendRegisterMobileOtp.operation-invoke
          #   - verifyOtpForRegister.operation-invoke
          #   - checkContactIdentity.operation-invoke
          #   - passwordLogin.operation-invoke
          #   - sendLoginOtp.operation-invoke
          #   - verifyLoginOtp.operation-invoke
          #   - enableBiometric.operation-invoke
          #   - biometricLogin.operation-invoke
          #   - disableBiometric.operation-invoke
          #   - firstTimeBindEmail.operation-invoke
          #   - sendFirstTimeBindMobileOtp.operation-invoke
          #   - firstTimeBindMobile.operation-invoke
          #   - addEmailBinding.operation-invoke
          #   - sendAddMobileBindingOtp.operation-invoke
          #   - addMobileBinding.operation-invoke
          #   - editEmailBinding.operation-invoke
          #   - removeEmailBinding.operation-invoke
          #   - editMobileBinding.operation-invoke
          #   - removeMobileBinding.operation-invoke
          #   - sendEditMobileOtp.operation-invoke
          #   - forgotPasswordByEmail.operation-invoke
          #   - sendForgotPasswordMobileOtp.operation-invoke
          #   - verifyForgotPasswordOtp.operation-invoke
          #   - resetForgottenPassword.operation-invoke
          #   - deleteAccount.operation-invoke
          #   - shared.time-control.now
          Given <dsl>
          When <dsl>
          Then 操作成功
          # @dsl
          # handler-candidate-kinds: response-verifier
          # rule: 先讀 ${SKILL_HOME}/aibdd-core/assets/boundaries/web-service/dsl-arrangement-rules/shared-then-success-law.md 理解成功情境下 Then 怎麼推理，再用其中 `後置（回應）` 小節判斷這裡該怎麼驗證操作成功後回應內容符合預期。
          # candidates:
          And <dsl>

    Rule: 後置（回應） - 同一號碼當日 OTP 發送達上限時應拒絕並提示「今日驗證碼發送次數已達上限，請明日再試」
        - 每日發送上限由 `wrs_otp_daily_limit` 控制（BR-23）。

        Example: <操作> 後 <回應主詞> 為 <期望值>
          # @dsl
          # handler-candidate-kinds: state-builder | operation-invoke | time-control | external-stub
          # rule: 先讀 ${SKILL_HOME}/aibdd-core/assets/boundaries/web-service/dsl-arrangement-rules/shared-given-law.md 理解 shared arrangement 作為你的推理流程，再讀 ${SKILL_HOME}/aibdd-core/assets/boundaries/web-service/dsl-arrangement-rules/given-delta-postcondition-response.md 補 `後置（回應）` 所需建構出的系統合法狀態。
          # candidates:
          #   - customers.state-builder
          #   - members.state-builder
          #   - member_center_profiles.state-builder
          #   - signUpByMail.operation-invoke
          #   - sendRegisterMobileOtp.operation-invoke
          #   - verifyOtpForRegister.operation-invoke
          #   - checkContactIdentity.operation-invoke
          #   - passwordLogin.operation-invoke
          #   - sendLoginOtp.operation-invoke
          #   - verifyLoginOtp.operation-invoke
          #   - enableBiometric.operation-invoke
          #   - biometricLogin.operation-invoke
          #   - disableBiometric.operation-invoke
          #   - firstTimeBindEmail.operation-invoke
          #   - sendFirstTimeBindMobileOtp.operation-invoke
          #   - firstTimeBindMobile.operation-invoke
          #   - addEmailBinding.operation-invoke
          #   - sendAddMobileBindingOtp.operation-invoke
          #   - addMobileBinding.operation-invoke
          #   - editEmailBinding.operation-invoke
          #   - removeEmailBinding.operation-invoke
          #   - editMobileBinding.operation-invoke
          #   - removeMobileBinding.operation-invoke
          #   - sendEditMobileOtp.operation-invoke
          #   - forgotPasswordByEmail.operation-invoke
          #   - sendForgotPasswordMobileOtp.operation-invoke
          #   - verifyForgotPasswordOtp.operation-invoke
          #   - resetForgottenPassword.operation-invoke
          #   - deleteAccount.operation-invoke
          #   - shared.time-control.now
          Given <dsl>
          When <dsl>
          Then 操作成功
          # @dsl
          # handler-candidate-kinds: response-verifier
          # rule: 先讀 ${SKILL_HOME}/aibdd-core/assets/boundaries/web-service/dsl-arrangement-rules/shared-then-success-law.md 理解成功情境下 Then 怎麼推理，再用其中 `後置（回應）` 小節判斷這裡該怎麼驗證操作成功後回應內容符合預期。
          # candidates:
          And <dsl>
