module Admin
  # ฟอร์ม "สร้างการประมูล" — รับวันที่ + เวลาเริ่ม (เวลาประเทศไทย) และระยะเวลา แล้วคำนวณ starts_at / ends_at
  # ค่าตั้งต้น: เริ่มชั่วโมงถัดไป (อย่างน้อยอีก 1 ชั่วโมง) และระยะเวลาตามที่ผู้ขายเสนอ
  class AuctionForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :auction_type, :string, default: "fpsba"
    attribute :start_date, :string
    attribute :start_time, :string
    attribute :duration_minutes, :integer

    attr_reader :product

    def initialize(product:, now: Time.current, **attributes)
      @product = product
      super(**attributes)
      default_start = (now + 1.hour).beginning_of_hour
      self.start_date ||= default_start.to_date.iso8601
      self.start_time ||= default_start.strftime("%H:%M")
      self.duration_minutes ||= product.desired_duration_minutes
    end

    # ตัวเลือกระยะเวลา = ตัวเลือกเดียวกับฟอร์มผู้ขาย (+ ค่าที่ผู้ขายเสนอ ถ้าไม่อยู่ในรายการ)
    def duration_choices
      (Product::DURATION_CHOICES + [ product.desired_duration_minutes ]).uniq.sort
    end

    def seller_duration?(minutes)
      minutes == product.desired_duration_minutes
    end

    def starts_at
      return if start_date.blank? || start_time.blank?

      Time.zone.parse("#{start_date} #{start_time}")
    rescue ArgumentError
      nil
    end

    def ends_at
      starts_at && duration_minutes && starts_at + duration_minutes.minutes
    end

    def auction_attributes
      { auction_type: auction_type, starts_at: starts_at, ends_at: ends_at }
    end

    # ย้าย error จาก Auction มาไว้ที่ field ของฟอร์ม
    def adopt_errors(auction)
      auction.errors.each do |error|
        field = { starts_at: :start_date, ends_at: :duration_minutes }.fetch(error.attribute, :base)
        errors.add(field, error.message)
      end
    end
  end
end
