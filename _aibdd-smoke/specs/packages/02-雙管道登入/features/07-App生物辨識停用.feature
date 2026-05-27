# @ignore - 等執行 /aibdd-red-execute 時，會只將 target Feature file 標注的 @ignore 拿掉，透過此手段來控制範疇。
@ignore
Feature: 在 App 端停用生物辨識登入
    # Action：已啟用生物辨識的會員於帳號設定點擊「停用」，後端撤銷該裝置 token、App 清除裝置上儲存的 token。
    # 來源：PRD §6.5、BR-62、T-123、T-126。

    Rule: 前置（參數） - 使用者必須處於 App 端帳號設定的「生物辨識登入：已啟用」狀態
        - Web 不支援此操作（BR-57）。
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

    Rule: 前置（狀態） - 使用者必須已登入
        - 停用屬於帳號設定操作。
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

    Rule: 後置（狀態） - 後端應撤銷該裝置的 refresh token
        - 後端記錄各裝置 token 以支援遠端撤銷（PRD §9 多裝置管理）。
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

    Rule: 後置（狀態） - App 應清除裝置上儲存的 refresh token
        - 下次開啟 App 不再顯示生物辨識提示（T-123）。
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

    Rule: 後置（狀態） - 停用單一裝置不應影響其他裝置的生物辨識登入
        - 同一帳號其他裝置仍可生物辨識登入（T-126）。
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

    Rule: 後置（回應） - 停用成功應在帳號設定顯示可重新「啟用」按鈕
        - 對應未啟用狀態 UI（BR-62）。

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
