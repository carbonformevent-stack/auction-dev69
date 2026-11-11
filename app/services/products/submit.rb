module Products
  # ผู้ขายส่งสินค้าให้ Admin ตรวจ: draft / rejected → pending_review
  class Submit
    def self.call(...) = new(...).call

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
