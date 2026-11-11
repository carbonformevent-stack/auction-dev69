module Admin
  # คิวสินค้ารอตรวจ และหน้าตรวจสินค้า
  class ProductsController < BaseController
    def index
      @products = Product.review_queue.includes(:seller).with_attached_images
    end

    def show
      @product = Product.includes(:seller, reviews: :reviewer).with_attached_images.find(params[:id])
    end
  end
end
