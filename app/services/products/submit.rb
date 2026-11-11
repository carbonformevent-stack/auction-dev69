module Products
  # ผู้ขายส่งสินค้าให้ Admin ตรวจ: draft / rejected → pending_review
  class Submit
    def self.call(...) = new(...).call

    # ข้อความ toast หลังส่งตรวจ (บรรทัดแรก = หัวเรื่อง) — ใช้ร่วมกันทุกจุดที่ส่งตรวจ
    def self.notice(product)
      "ส่งตรวจสอบแล้ว\n#{product.title} อยู่ในคิวของทีมตรวจสอบ"
    end

    def initialize(product:, user:)
      @product = product
      @user = user
    end

    def call
      raise ActiveRecord::RecordNotFound unless @product.owned_by?(@user)
      raise Product::InvalidTransition unless @product.editable?
      raise ActiveRecord::RecordInvalid, @product unless @product.valid?(:submit)

      @product.transition!(from: %i[draft rejected], to: :pending_review, submitted_at: Time.current)
    end
  end
end
