module Admin
  # คิวสินค้ารอตรวจ และหน้าตรวจสินค้า
  class ProductsController < BaseController
    def index
      @stats = Admin::ReviewQueueStats.new
      @category_counts = Product.pending_review.group(:category).count
      @category = Product.categories.key?(params[:category].to_s) ? params[:category].to_s : nil

      queue = Product.review_queue
      queue = queue.where(category: @category) if @category
      @products = queue.includes(:seller, :reviews).with_attached_images.with_attached_certificate
    end

    def show
      @product = Product.includes(:seller, reviews: :reviewer).with_attached_images.find(params[:id])
    end
  end
end
