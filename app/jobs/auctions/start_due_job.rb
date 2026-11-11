module Auctions
  # กันพลาด: เปิดทุก auction ที่ถึง starts_at แล้วแต่ยังเป็น scheduled
  # (เช่น server restart ตอนที่ StartJob ควรทำงาน) — รันทุก 1 นาทีผ่าน config/recurring.yml
  class StartDueJob < ApplicationJob
    queue_as :default

    def perform
      Auction.due_to_start.find_each { |auction| Start.call(auction: auction) }
    end
  end
end
