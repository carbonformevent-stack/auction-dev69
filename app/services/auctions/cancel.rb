module Auctions
  # Admin ยกเลิกรอบประมูลที่ยังไม่เริ่ม: scheduled → cancelled ("ยกเลิกได้ก่อนเริ่ม" ตาม Design canvas หน้า 6)
  # running → cancelled (กรณีพิเศษใน auction-design.md §3) ยังไม่เปิดใน story นี้
  # สินค้ากลับไปพร้อมจัดประมูลใหม่ได้ (partial unique index นับเฉพาะรอบที่ active)
  class Cancel
    def self.call(...) = new(...).call

    def initialize(auction:)
      @auction = auction
    end

    def call
      @auction.transition!(from: :scheduled, to: :cancelled)
      @auction
    end
  end
end
