module Products
  # ลบใบรับรอง (PDF) ของสินค้า — ไฟล์ถูกลบจาก storage ด้วย
  class CertificatesController < ApplicationController
    def destroy
      product = current_user.products.find(params[:product_id])
      return redirect_to(product, alert: product.edit_blocked_reason) unless product.editable_by?(current_user)

      product.certificate.purge if product.certificate.attached?
      redirect_to edit_product_path(product), notice: "ลบใบรับรองแล้ว", status: :see_other
    end
  end
end
