# ล็อกอินจำลองสำหรับ local development — ใช้เมื่อยังไม่มี Keycloak
#
# เปิดด้วย DEV_LOGIN=1 ใน .env (เฉพาะ development) แล้วหน้า /sign_in จะมีปุ่ม "เข้าเป็นผู้ขาย/Admin ทดสอบ"
# ใช้ test mode ของ OmniAuth: ยังวิ่งผ่าน callback และ User.from_omniauth ตัวจริง แค่ข้ามขั้นไป Keycloak
# บัญชีและข้อมูลตัวอย่างสร้างด้วย `bin/rails db:seed` (db/seeds/development.rb)
require_relative "../../lib/dev_login"

if DevLogin.enabled?
  OmniAuth.config.test_mode = true

  OmniAuth.config.before_request_phase do |env|
    account = DevLogin::ACCOUNTS[Rack::Request.new(env).params["role"].to_s]

    OmniAuth.config.mock_auth[:keycloak] =
      if account
        OmniAuth::AuthHash.new(provider: "keycloak", uid: account[:uid], info: { email: account[:email], name: account[:name] })
      else
        :invalid_credentials # ไม่ระบุ role ที่รู้จัก → ไปหน้า failure ตามปกติ ไม่ล็อกอินเป็นใครโดยปริยาย
      end
  end

  Rails.logger&.warn("[dev_login] ล็อกอินจำลองเปิดอยู่ — ไม่ผ่าน Keycloak (development เท่านั้น)")
end
