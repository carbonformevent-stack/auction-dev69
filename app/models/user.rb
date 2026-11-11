# ผู้ใช้ 1 บัญชีเป็นได้ทั้งผู้ขายและผู้ประมูล — แยกสิทธิ์ด้วย role (user/admin) เท่านั้น
# การยืนยันตัวตนทำผ่าน Keycloak (OpenID Connect) ไม่มี password ในระบบนี้
class User < ApplicationRecord
  devise :omniauthable, omniauth_providers: %i[keycloak]

  enum :role, { user: 0, admin: 1 }, default: :user, validate: true

  has_many :products, foreign_key: :seller_id, inverse_of: :seller, dependent: :restrict_with_exception

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :provider, :uid, presence: true
  validates :uid, uniqueness: { scope: :provider }

  normalizes :email, with: ->(email) { email.strip.downcase }

  # สร้างหรืออัปเดต User จากข้อมูลที่ Keycloak ส่งกลับมา
  # role ไม่ถูกแตะ — กำหนดในระบบเราเท่านั้น
  def self.from_omniauth(auth)
    user = find_or_initialize_by(provider: auth.provider.to_s, uid: auth.uid.to_s)
    user.email = auth.info.email
    user.name = auth.info.name.presence || auth.info.email
    user.save!
    user
  end

  def display_name
    name.presence || email
  end
end
