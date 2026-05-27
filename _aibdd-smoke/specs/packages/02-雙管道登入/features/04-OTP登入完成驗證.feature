# @ignore - 等執行 /aibdd-red-execute 時，會只將 target Feature file 標注的 @ignore 拿掉，透過此手段來控制範疇。
@ignore
Feature: 以 OTP 驗證碼完成 OTP 登入
    # Action：使用者輸入收到的 OTP，呼叫 verify-otp（LOGIN 用途），驗證成功即完成登入（不需密碼）。
    # 來源：PRD §5.9 步驟 8-11、BR-52/53/54、T-106、T-107、T-109、T-110、T-111、T-115、T-116。

    Rule: 前置（參數） - 使用者必須提供前一步取得的 OTP uuid
        - 不可偽造、不可重複使用（BR-52）。
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

    Rule: 前置（參數） - 使用者必須提供與發送內容相符的 OTP 驗證碼
        - 錯誤應拒絕並提示「驗證碼錯誤」（T-109）。
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

    Rule: 前置（狀態） - 該 OTP 必須仍在有效期限內
        - 有效期由 `wrs_otp_expiry_sec` 控制（BR-22、T-110）。
        - 過期應回傳「驗證碼已過期，請重新發送」。
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

    Rule: 前置（狀態） - 該 OTP 必須是 LOGIN 用途、且通道（Email/SMS）與帳號類型一致
        - REGISTER 用途 OTP 不可用於 LOGIN 驗證（BR-52、T-111）。
        - Email OTP 與 SMS OTP 不互通（T-115）。
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

    Rule: 後置（狀態） - 驗證成功時系統應直接建立登入會話
        - OTP 驗證成功即完成登入，不需額外輸入密碼（BR-53、T-116）。
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

    Rule: 後置（回應） - 驗證成功應回傳成功結果讓使用者進入會員中心
        - 前端據此導向登入後狀態。

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
