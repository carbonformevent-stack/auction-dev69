# สินค้าที่ผู้ขายลง — ต้องผ่านการตรวจของ Admin ก่อนนำไปประมูล
# draft → pending_review → approved / rejected (rejected แก้แล้วส่งใหม่ได้)
# เปลี่ยนสถานะผ่าน service ใน app/services/products/ เท่านั้น
class Product < ApplicationRecord
  class InvalidTransition < StandardError
    def initialize(msg = "สถานะสินค้าเปลี่ยนไปแล้ว กรุณาโหลดหน้าใหม่")
      super
    end
  end

  PRICE_RANGE = 1..20_000
  DURATION_RANGE = 60..10_080 # นาที: 1 ชั่วโมง – 7 วัน
  DURATION_CHOICES = [ 60, 360, 1440, 4320, 7200, 10_080 ].freeze
  MAX_IMAGES = 12
  MAX_IMAGE_SIZE = 5.megabytes
  MAX_CERTIFICATE_SIZE = 10.megabytes
  IMAGE_TYPES = %w[image/jpeg image/png image/webp].freeze

  belongs_to :seller, class_name: "User"
  has_many :reviews, -> { order(:created_at, :id) }, class_name: "ProductReview",
                                                       inverse_of: :product, dependent: :restrict_with_exception

  has_many_attached :images
  has_one_attached :certificate

  enum :category, { watch: 0, jewelry: 1, old_book: 2, painting: 3 },
       validate: { allow_nil: true, message: "ประเภทสินค้าไม่ถูกต้อง" }
  enum :status, { draft: 0, pending_review: 1, approved: 2, rejected: 3 }

  validates :category, presence: { message: "กรุณาเลือกประเภทสินค้า" }
  validates :starting_price, numericality: { only_integer: true, in: PRICE_RANGE, message: "ราคาต้องอยู่ระหว่าง 1–20,000 บาท" }
  validates :title, presence: { message: "กรุณากรอกชื่อสินค้า" },
                    length: { maximum: 150, message: "ชื่อสินค้ายาวได้ไม่เกิน 150 ตัวอักษร" }
  validates :description, presence: { message: "กรุณากรอกรายละเอียดสินค้า" },
                          length: { maximum: 5000, message: "รายละเอียดยาวได้ไม่เกิน 5,000 ตัวอักษร" }
  validates :desired_duration_minutes, numericality: { only_integer: true, in: DURATION_RANGE,
                                                       message: "ระยะเวลาต้องอยู่ระหว่าง 1 ชั่วโมง – 7 วัน" }
  validate :validate_images
  validate :validate_certificate
  validate :validate_images_present, on: :submit

  scope :review_queue, -> { pending_review.order(:submitted_at, :id) }

  def editable?
    draft? || rejected?
  end

  def owned_by?(user)
    user.present? && seller_id == user.id
  end

  def editable_by?(user)
    owned_by?(user) && editable?
  end

  def submittable_by?(user)
    editable_by?(user)
  end

  def destroyable_by?(user)
    owned_by?(user) && draft?
  end

  # ข้อความเมื่อแก้ไขไม่ได้ (nil = แก้ได้)
  def edit_blocked_reason
    if pending_review? then "สินค้ากำลังรอตรวจ แก้ไขไม่ได้"
    elsif approved? then "สินค้าที่อนุมัติแล้วแก้ไขไม่ได้"
    end
  end

  def latest_rejection
    reviews.select(&:rejected?).last
  end

  def cover_image
    images.first
  end

  # เปลี่ยนสถานะแบบ "ใครมาก่อนได้ก่อน" — UPDATE ... WHERE status IN (from)
  # SQLite ไม่มี SELECT ... FOR UPDATE จึงใช้ conditional update แทน row lock
  # ถ้าสถานะไม่ตรง (เช่น Admin อีกคนตัดสินไปแล้ว) จะ raise InvalidTransition
  def transition!(from:, to:, **attributes)
    now = Time.current
    changes = attributes.merge(status: self.class.statuses.fetch(to.to_s), updated_at: now)
    updated = self.class.where(id: id, status: Array(from)).update_all(changes)
    raise InvalidTransition if updated.zero?

    reload
  end

  private

  def validate_images
    errors.add(:images, "อัปโหลดได้สูงสุด #{MAX_IMAGES} รูป") if images.size > MAX_IMAGES

    images.each do |image|
      blob = image.blob
      unless IMAGE_TYPES.include?(blob.content_type)
        errors.add(:images, "#{blob.filename}: รับเฉพาะไฟล์ JPG, PNG หรือ WebP")
      end
      errors.add(:images, "#{blob.filename}: ไฟล์ใหญ่เกิน 5MB") if blob.byte_size > MAX_IMAGE_SIZE
    end
  end

  def validate_certificate
    return unless certificate.attached?

    blob = certificate.blob
    errors.add(:certificate, "ใบรับรองต้องเป็นไฟล์ PDF") unless blob.content_type == "application/pdf"
    errors.add(:certificate, "ใบรับรองต้องไม่เกิน 10MB") if blob.byte_size > MAX_CERTIFICATE_SIZE
  end

  def validate_images_present
    errors.add(:images, "ต้องมีรูปอย่างน้อย 1 รูป") if images.none?
  end
end
