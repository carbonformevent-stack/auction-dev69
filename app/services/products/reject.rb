module Products
  # Admin ปฏิเสธสินค้าพร้อมเหตุผล: pending_review → rejected พร้อมบันทึกประวัติใน transaction เดียวกัน
  class Reject
    def self.call(...) = new(...).call

    def initialize(product:, reviewer:, reason:)
      @product = product
      @reviewer = reviewer
      @reason = reason
    end

    def call
      review = ProductReview.new(product: @product, reviewer: @reviewer, decision: :rejected, reason: @reason)
      review.validate!

      Product.transaction do
        @product.transition!(from: :pending_review, to: :rejected)
        review.save!
      end
      @product
    end
  end
end
