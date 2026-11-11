module Admin
  module Products
    class RejectionsController < BaseController
      def create
        product = Product.find(params[:product_id])
        ::Products::Reject.call(product: product, reviewer: current_user, reason: params.dig(:rejection, :reason))
        redirect_to admin_products_path, notice: "ไม่อนุมัติ \"#{product.title}\" แล้ว ผู้ขายจะเห็นเหตุผล"
      rescue ActiveRecord::RecordInvalid => e
        redirect_to admin_product_path(product), alert: e.record.errors.full_messages.to_sentence
      rescue Product::InvalidTransition => e
        redirect_to admin_product_path(product), alert: e.message
      end
    end
  end
end
