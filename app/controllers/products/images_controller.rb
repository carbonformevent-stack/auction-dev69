module Products
  # ลบรูปสินค้าทีละรูป — ไฟล์ถูกลบจาก storage ด้วย
  class ImagesController < ApplicationController
    def destroy
      product = current_user.products.find(params[:product_id])
      return redirect_to(product, alert: product.edit_blocked_reason) unless product.editable_by?(current_user)

      product.images.find(params[:id]).purge
      redirect_to edit_product_path(product), notice: "ลบรูปแล้ว", status: :see_other
    end
  end
end
