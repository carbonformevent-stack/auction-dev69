# ประวัติการตรวจสินค้า (audit trail) — สร้างได้อย่างเดียว แก้ไข/ลบไม่ได้
class ProductReview < ApplicationRecord
  belongs_to :product, inverse_of: :reviews
  belongs_to :reviewer, class_name: "User"

  enum :decision, { approved: 0, rejected: 1 }, validate: true

  normalizes :reason, with: ->(reason) { reason.strip.presence }

  validates :reason, presence: { message: "กรุณาระบุเหตุผล" }, if: :rejected?
  validates :reason, length: { maximum: 1000, message: "เหตุผลยาวได้ไม่เกิน 1,000 ตัวอักษร" }

  def readonly?
    persisted? || super
  end
end
