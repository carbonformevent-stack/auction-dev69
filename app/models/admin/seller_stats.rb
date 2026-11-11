# สถิติผู้ขายบนการ์ด "ผู้ขาย" ของหน้าตรวจสินค้า — ให้ Admin เห็นประวัติเพื่อประกอบการตัดสินใจ
module Admin
  class SellerStats
    def initialize(seller)
      @seller = seller
    end

    # สินค้าทั้งหมดที่ผู้ขายลง (รวมแบบร่าง)
    def listed = @seller.products.count

    # จำนวนผลตรวจทุกรอบ — สินค้าที่ถูกตีกลับหลายรอบนับทุกรอบ
    def approved = reviews.approved.count

    def rejected = reviews.rejected.count

    private

    def reviews = ProductReview.joins(:product).where(products: { seller_id: @seller.id })
  end
end
