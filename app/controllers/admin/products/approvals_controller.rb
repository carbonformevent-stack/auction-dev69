module Admin
  module Products
    class ApprovalsController < BaseController
      def create
        product = Product.find(params[:product_id])
        ::Products::Approve.call(product: product, reviewer: current_user)
        redirect_to admin_products_path, notice: "อนุมัติ \"#{product.title}\" แล้ว"
      rescue Product::InvalidTransition => e
        redirect_to admin_product_path(product), alert: e.message
      end
    end
  end
end
