module Auctions
  # Admin สร้างรอบประมูลจากสินค้าที่อนุมัติแล้ว → scheduled แล้วตั้ง job เปิดรับราคาเมื่อถึง starts_at
  # - ราคาเริ่มต้นคัดลอกจากสินค้า ณ เวลาสร้าง (snapshot)
  # - สินค้า 1 ชิ้น active ได้ครั้งละ 1 รอบ — partial unique index กันกรณี Admin 2 คนกดพร้อมกัน
  # คืน Auction เสมอ: persisted? = สำเร็จ, ไม่สำเร็จดู errors
  class Create
    def self.call(...) = new(...).call

    def initialize(product:, admin:, auction_type:, starts_at:, ends_at:)
      @product = product
      @admin = admin
      @attributes = { auction_type: auction_type, starts_at: starts_at, ends_at: ends_at }
    end

    def call
      auction = @product.auctions.new(@attributes.merge(created_by: @admin, starting_price: @product.starting_price))
      return auction unless product_ready?(auction) && auction.valid?

      save(auction)
    end

    private

    def product_ready?(auction)
      if !@product.approved?
        auction.errors.add(:base, "สร้างการประมูลได้เฉพาะสินค้าที่อนุมัติแล้ว")
      elsif @product.auctions.active.exists?
        auction.errors.add(:base, already_active_message)
      end
      auction.errors.empty?
    end

    def save(auction)
      auction.save!
      StartJob.set(wait_until: auction.starts_at).perform_later(auction)
      auction
    rescue ActiveRecord::RecordNotUnique
      auction.errors.add(:base, already_active_message)
      auction
    end

    def already_active_message
      "สินค้านี้มีรอบประมูลที่ยังไม่จบอยู่แล้ว"
    end
  end
end
