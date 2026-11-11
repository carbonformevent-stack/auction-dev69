# ประวัติการตรวจสินค้า (audit trail) — สร้างได้อย่างเดียว แก้ไข/ลบไม่ได้
class ProductReview < ApplicationRecord
  belongs_to :product, inverse_of: :reviews
  belongs_to :reviewer, class_name: "User"

  enum :decision, { approved: 0, rejected: 1 }, validate: true

  normalizes :reason, with: ->(reason) { reason.strip.presence }

  # เหตุผลที่ไม่อนุมัติต้องพอให้ผู้ขายนำไปแก้ได้ — ว่างจะฟ้องแค่ "กรุณาระบุเหตุผล" (allow_blank กันฟ้องซ้ำ)
  MIN_REJECTION_REASON = 10

  validates :reason, presence: { message: "กรุณาระบุเหตุผล" }, if: :rejected?
  validates :reason, length: { minimum: MIN_REJECTION_REASON, allow_blank: true,
                               message: "เหตุผลต้องมีอย่างน้อย #{MIN_REJECTION_REASON} ตัวอักษร" }, if: :rejected?
  validates :reason, length: { maximum: 1000, message: "เหตุผลยาวได้ไม่เกิน 1,000 ตัวอักษร" }

  def readonly?
    persisted? || super
  end
end
