module Products
  # Admin อนุมัติสินค้า: pending_review → approved พร้อมบันทึกประวัติใน transaction เดียวกัน
  class Approve
    def self.call(...) = new(...).call

    def initialize(product:, reviewer:)
      @product = product
      @reviewer = reviewer
    end

    def call
      Product.transaction do
        @product.transition!(from: :pending_review, to: :approved)
        @product.reviews.create!(reviewer: @reviewer, decision: :approved)
      end
      @product
    end
  end
end
