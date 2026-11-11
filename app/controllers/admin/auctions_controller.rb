module Admin
  # "การประมูล": สินค้าที่อนุมัติแล้วรอจัดประมูล + รอบประมูลทั้งหมด (ล่าสุดก่อน)
  class AuctionsController < BaseController
    def index
      @ready_products = Product.ready_for_auction.includes(:seller, :reviews).with_attached_images.order(:updated_at, :id)
      @auctions = Auction.recent_first.includes(:created_by, product: { images_attachments: :blob })
    end
  end
end
