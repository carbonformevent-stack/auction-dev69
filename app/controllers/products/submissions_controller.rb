module Products
  # ผู้ขายกด "ส่งตรวจ"
  class SubmissionsController < ApplicationController
    def create
      product = current_user.products.find(params[:product_id])
      Products::Submit.call(product: product, user: current_user)
      # บรรทัดแรกเป็นหัวเรื่องของ toast บรรทัดที่สองเป็นรายละเอียด
      redirect_to product, notice: "ส่งตรวจสอบแล้ว\n#{product.title} อยู่ในคิวของทีมตรวจสอบ"
    rescue ActiveRecord::RecordInvalid => e
      redirect_to product, alert: "ส่งตรวจไม่ได้: #{e.record.errors.full_messages.to_sentence}"
    rescue Product::InvalidTransition
      redirect_to product, alert: product.edit_blocked_reason || "ส่งตรวจไม่ได้ในสถานะนี้"
    end
  end
end
