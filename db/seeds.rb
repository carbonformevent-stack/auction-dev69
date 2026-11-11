# ตั้ง admin คนแรก: ผู้ใช้ต้อง login ผ่าน Keycloak มาก่อน 1 ครั้ง แล้วรัน
#   ADMIN_EMAIL=someone@example.com bin/rails db:seed
admin_email = ENV["ADMIN_EMAIL"].to_s.strip.downcase

if admin_email.present?
  user = User.find_by(email: admin_email)
  if user
    user.admin!
    puts "Promoted #{admin_email} to admin"
  else
    puts "ADMIN_EMAIL=#{admin_email} not found — login via Keycloak first, then re-run db:seed"
  end
end

# บัญชีทดสอบ + สินค้าตัวอย่างสำหรับ local development (ไม่ทำงานใน test/production)
load Rails.root.join("db/seeds/development.rb") if Rails.env.development?
