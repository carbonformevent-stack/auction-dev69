module Admin
  module Products
    # หน้า "สร้างการประมูล" ของสินค้าที่อนุมัติแล้ว
    class AuctionsController < BaseController
      before_action :set_product
      before_action :require_ready_product

      def new
        @form = AuctionForm.new(product: @product)
      end

      def create
        @form = AuctionForm.new(product: @product, **form_params)
        auction = ::Auctions::Create.call(product: @product, admin: current_user, **@form.auction_attributes)

        if auction.persisted?
          redirect_to admin_auctions_path, notice: created_message(auction)
        else
          @form.adopt_errors(auction)
          render :new, status: :unprocessable_content
        end
      end

      private

      def set_product
        @product = Product.with_attached_images.includes(:seller, :reviews).find(params[:product_id])
      end

      def require_ready_product
        return if @product.ready_for_auction?

        redirect_to admin_auctions_path, alert: not_ready_message
      end

      def form_params
        params.expect(auction: %i[auction_type start_date start_time duration_minutes]).to_h.symbolize_keys
      end

      def created_message(auction)
        "สร้างการประมูลแล้ว · สถานะ “กำหนดการ” จะเปิดรับราคาอัตโนมัติ #{helpers.thai_datetime_full(auction.starts_at)}"
      end

      def not_ready_message
        @product.approved? ? "สินค้านี้มีรอบประมูลที่ยังไม่จบอยู่แล้ว" : "สร้างการประมูลได้เฉพาะสินค้าที่อนุมัติแล้ว"
      end
    end
  end
end
