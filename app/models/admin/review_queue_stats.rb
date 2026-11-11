# ตัวเลขสรุปบนหัวคิวรอตรวจของ Admin — คำนวณสดทุกครั้งที่เปิดหน้า (ปริมาณข้อมูลยังน้อย)
module Admin
  class ReviewQueueStats
    # สินค้าที่รอตรวจอยู่
    def pending = queue.count

    # รอเกิน SLA (Product::REVIEW_SLA) — "เกิน" หมายถึงมากกว่า ไม่รวมพอดี
    def overdue = queue.where(submitted_at: ...(Time.current - Product::REVIEW_SLA)).count

    # ส่งใหม่หลังถูกตีกลับ (นับสินค้าละ 1 ไม่ว่าถูกตีกลับกี่รอบ)
    def resubmitted = queue.where(id: ProductReview.rejected.select(:product_id)).count

    # ผลตรวจที่ Admin ทุกคนทำวันนี้ (ตามเวลาประเทศไทย)
    def reviewed_today = ProductReview.where(created_at: Time.current.all_day).count

    private

    def queue = Product.pending_review
  end
end
