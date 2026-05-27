# @ignore - 等執行 /aibdd-red-execute 時，會只將 target Feature file 標注的 @ignore 拿掉，透過此手段來控制範疇。
@ignore
Feature: 為已登入會員補綁手機發送 SMS OTP 驗證碼
    # Action：已登入會員在帳號設定點擊「綁定手機」並輸入手機後，點擊「發送驗證碼」由後端發送 SMS OTP。
    # 來源：PRD §5.5 + §6.4、BR-11/12/13/23/36/37、T-38、T-41。

    Rule: 前置（參數） - 會員必須處於已登入狀態
        - 此操作位於帳號設定頁。
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

    Rule: 前置（參數） - 會員提供的新手機號碼必須為正規化後 `+886` + 9 位數字
        - 帳號設定頁固定走手機格式驗證（PRD §6.4），不需統一欄位識別（BR-29）。
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

    Rule: 前置（狀態） - 該會員必須尚未綁定手機
        - 已雙綁定者不再顯示「綁定」按鈕（PRD §6.4）。
        - 既有手機會員依方向規則僅可補綁 Email（BR-11）。
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

    Rule: 前置（狀態） - 該手機號碼必須尚未被其他帳號使用
        - 唯一性檢查（BR-12、T-41）。
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

    Rule: 後置（回應） - 發送成功應回傳 OTP uuid 供後續 verify 使用
        - otpToken 沿用既有 uuid。
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

    Rule: 後置（回應） - 手機已被使用應拒絕並提示「此手機號碼已被使用，請改用其他手機號碼」
        - 後端錯誤訊息由前端直接顯示（BR-33、T-41）。
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
