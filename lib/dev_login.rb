# บัญชีทดสอบสำหรับ local development เท่านั้น — ใช้ร่วมกันระหว่าง db/seeds/development.rb
# และ config/initializers/dev_login.rb (ล็อกอินจำลองแทน Keycloak)
#
# ไม่โหลดใน production: ทั้งสองไฟล์ตรวจ Rails.env.development? ก่อนใช้งาน
# อีเมลใช้โดเมน .test (สงวนไว้ตาม RFC 2606) เพื่อไม่ให้ชนกับอีเมลจริง
module DevLogin
  ACCOUNTS = {
    "seller" => { uid: "dev-seller", email: "seller@example.test", name: "ผู้ขายทดสอบ", role: :user },
    "admin" => { uid: "dev-admin", email: "admin@example.test", name: "แอดมินทดสอบ", role: :admin }
  }.freeze

  # ผู้ขายอีกคน เจ้าของสินค้าตัวอย่างบางชิ้นในคิว Admin (ไม่มีปุ่มล็อกอิน)
  OTHER_SELLER = { uid: "dev-seller-2", email: "arunee@example.test", name: "อรุณี สุขใจ", role: :user }.freeze

  # เปิดใช้ต้อง "ตั้งใจ": development + DEV_LOGIN=1 เท่านั้น
  # (คนที่ต่อ Keycloak จริงใน dev อยู่แล้วจะไม่ถูกแทนที่โดยไม่รู้ตัว)
  def self.enabled?
    defined?(Rails) && Rails.env.development? && ENV["DEV_LOGIN"] == "1"
  end
end
