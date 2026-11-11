module Auctions
  # scheduled → running เมื่อถึง starts_at (เรียกจาก StartJob)
  # ยังไม่ถึงเวลา หรือสถานะเปลี่ยนไปแล้ว (เช่น ถูกยกเลิก) → ไม่ทำอะไร คืน false
  class Start
    def self.call(...) = new(...).call

    def initialize(auction:, now: Time.current)
      @auction = auction
      @now = now
    end

    def call
      return false unless @auction.scheduled? && @auction.starts_at <= @now

      @auction.transition!(from: :scheduled, to: :running)
      true
    rescue Auction::InvalidTransition
      false
    end
  end
end
