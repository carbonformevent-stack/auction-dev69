module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    def keycloak
      auth = request.env["omniauth.auth"]
      user = User.from_omniauth(auth)
      # เก็บ id_token ไว้ส่งเป็น id_token_hint ตอน logout — Keycloak จะปิด SSO session ทันทีโดยไม่ถามยืนยัน
      session[SessionsController::ID_TOKEN_KEY] = auth.credentials&.id_token
      set_flash_message(:notice, :success, kind: "Keycloak") if is_navigational_format?
      sign_in_and_redirect user, event: :authentication
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.warn("[auth] Keycloak login rejected: #{e.message}")
      redirect_to new_user_session_path, alert: "ไม่สามารถเข้าสู่ระบบได้: ข้อมูลบัญชีจาก Keycloak ไม่ครบ (ต้องมี email)"
    end

    def failure
      error = request.env["omniauth.error"]
      Rails.logger.warn("[auth] Keycloak login failed: #{failure_message} " \
                        "(#{error.class}: #{error&.message.to_s.truncate(200)})")
      redirect_to new_user_session_path, alert: "เข้าสู่ระบบไม่สำเร็จ กรุณาลองใหม่อีกครั้ง"
    end
  end
end
