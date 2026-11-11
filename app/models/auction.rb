# รอบการประมูลของสินค้า 1 ชิ้น — สินค้ามีได้หลายรอบ แต่ active (scheduled/running) ได้ครั้งละ 1
# scheduled → running → closed → settled, ยกเลิกได้ก่อนเริ่ม (ดู docs/architecture/auction-design.md §3)
# เปลี่ยนสถานะผ่าน service ใน app/services/auctions/ เท่านั้น
class Auction < ApplicationRecord
  class InvalidTransition < StandardError
    def initialize(msg = "สถานะการประมูลเปลี่ยนไปแล้ว กรุณาโหลดหน้าใหม่")
      super
    end
  end

  DURATION_RANGE = Product::DURATION_RANGE # นาที: 1 ชั่วโมง – 7 วัน (เท่ากับที่ผู้ขายเสนอได้)
  ACTIVE_STATUSES = %i[scheduled running].freeze

  belongs_to :product
  belongs_to :created_by, class_name: "User"

  enum :auction_type, { fpsba: 0 }, validate: { message: "วิธีประมูลไม่ถูกต้อง" }
  enum :status, { scheduled: 0, running: 1, closed: 2, settled: 3, cancelled: 4 }

  validates :starts_at, presence: { message: "กรุณาระบุเวลาเริ่ม" }
  validates :ends_at, presence: { message: "กรุณาระบุเวลาสิ้นสุด" }
  validates :starting_price, numericality: { only_integer: true, in: Product::PRICE_RANGE,
                                             message: "ราคาเริ่มต้นต้องอยู่ระหว่าง 1–20,000 บาท" }
  validate :validate_duration
  validate :validate_starts_in_future, on: :create

  scope :active, -> { where(status: ACTIVE_STATUSES) }
  scope :due_to_start, ->(now = Time.current) { scheduled.where(starts_at: ..now) }
  scope :recent_first, -> { order(created_at: :desc, id: :desc) }

  def duration_minutes
    return unless starts_at && ends_at

    ((ends_at - starts_at) / 60).round
  end

  def active?
    scheduled? || running?
  end

  # ยกเลิกได้ก่อนเริ่ม (ดู Auctions::Cancel)
  def cancellable?
    scheduled?
  end

  # เปลี่ยนสถานะแบบ "ใครมาก่อนได้ก่อน" เหมือน Product#transition! (SQLite ไม่มี row lock)
  def transition!(from:, to:, **attributes)
    changes = attributes.merge(status: self.class.statuses.fetch(to.to_s), updated_at: Time.current)
    updated = self.class.where(id: id, status: Array(from)).update_all(changes)
    raise InvalidTransition if updated.zero?

    reload
  end

  private

  def validate_duration
    minutes = duration_minutes
    return if minutes.nil? || DURATION_RANGE.cover?(minutes)

    errors.add(:ends_at, "ระยะเวลาต้องอยู่ระหว่าง 1 ชั่วโมง – 7 วัน")
  end

  def validate_starts_in_future
    return if starts_at.nil? || starts_at > Time.current

    errors.add(:starts_at, "เวลาเริ่มต้องอยู่หลังเวลาปัจจุบัน")
  end
end
