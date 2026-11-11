module Admin
  module ProductsHelper
    # ตำแหน่งของสินค้าในคิวรอตรวจ [ลำดับ, ทั้งหมด] — nil ถ้าไม่ได้อยู่ในคิว (ตัดสินแล้ว)
    def queue_position(product)
      ids = Product.review_queue.ids
      index = ids.index(product.id)
      index && [ index + 1, ids.size ]
    end
  end
end
