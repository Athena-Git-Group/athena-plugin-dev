# @ignore - 等執行 /aibdd-red-execute 時，會只將 target Feature file 標注的 @ignore 拿掉，透過此手段來控制範疇。
@ignore
Feature: 以 SMS OTP 完成編輯已綁定手機
    # Action：已登入會員輸入收到的 OTP，verify 成功後將新手機寫入會員 Customer 紀錄並覆蓋舊手機。
    # 來源：PRD §5.7、BR-45/46、T-91、T-94、T-96、T-97。

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

    Rule: 前置（參數） - 會員必須提供前一步取得的 OTP uuid
        - 不可偽造、不可重複使用。
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

    Rule: 前置（參數） - 會員必須提供與發送內容相符的 OTP 驗證碼
        - 錯誤應拒絕並提示驗證碼錯誤（T-94）。
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
        - 有效期由 `wrs_otp_expiry_sec` 控制（BR-22）。
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

    Rule: 前置（狀態） - 新手機號碼必須仍尚未被其他帳號使用
        - 二次唯一性檢查（BR-46）。
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

    Rule: 後置（狀態） - 系統應以新手機號碼覆蓋該會員 Customer 的 mobilePhone 欄位
        - 舊手機不再可用於登入（T-96）。
        - 新手機可用於登入（T-97）。
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

    Rule: 後置（狀態） - 系統應寄送一則變更確認簡訊到新手機號碼
        - CLARIFY-04 已確認：通知僅送至新聯絡方式以確認可接收，舊手機不另行通知。
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

    Rule: 後置（回應） - 更新成功應在帳號設定頁顯示新手機
        - 切換至更新後狀態 UI（T-91）。

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
