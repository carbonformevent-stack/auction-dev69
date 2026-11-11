module Admin
  module Products
    class RejectionsController < BaseController
      def create
        @product = Product.for_admin_review.find(params[:product_id])
        ::Products::Reject.call(product: @product, reviewer: current_user, reason: reason)
        redirect_to admin_products_path, notice: "ไม่อนุมัติ \"#{@product.title}\" แล้ว ผู้ขายจะเห็นเหตุผล"
      rescue ActiveRecord::RecordInvalid => e
        # เหตุผลไม่ผ่าน: แสดงหน้าตรวจเดิม เก็บข้อความที่พิมพ์ไว้ และเปิด dialog ให้แก้ต่อ (ไม่ redirect ทิ้งข้อความ)
        @rejection_reason = reason
        @rejection_errors = e.record.errors[:reason]
        # Reject สร้าง ProductReview ที่ยังไม่บันทึกแล้วผูกเข้า @product.reviews (has_many_inversing)
        # ต้องโหลดใหม่ ไม่เช่นนั้นประวัติจะมี "ผลตรวจผี" และนับรอบส่งใหม่เกิน
        @product = Product.for_admin_review.find(params[:product_id])
        render "admin/products/show", status: :unprocessable_content
      rescue Product::InvalidTransition => e
        redirect_to admin_product_path(@product), alert: e.message
      end

      private

      def reason = params.dig(:rejection, :reason)
    end
  end
end
