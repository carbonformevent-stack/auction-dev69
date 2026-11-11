module Auctions
  # เปิดรับราคาเมื่อถึง starts_at — enqueue ตอนสร้าง (wait_until: starts_at)
  # - timer ของ queue อาจปลุกเร็วกว่า starts_at เล็กน้อย → ตั้งตัวเองใหม่ให้ตรงเวลา
  # - ถ้า auction ถูกยกเลิกหรือเริ่มไปแล้ว Start จะไม่ทำอะไร
  class StartJob < ApplicationJob
    queue_as :default
    discard_on ActiveJob::DeserializationError

    def perform(auction)
      return if Start.call(auction: auction)

      self.class.set(wait_until: auction.starts_at).perform_later(auction) if auction.scheduled? && auction.starts_at.future?
    end
  end
end
