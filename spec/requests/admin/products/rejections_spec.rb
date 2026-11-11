require "rails_helper"

RSpec.describe "Admin::Products::Rejections" do
  let(:product) { create(:product, :pending_review) }
  let(:admin) { create(:user, :admin) }

  def reject_with(reason)
    post admin_product_rejection_path(product), params: { rejection: { reason: reason } }
  end

  describe "POST /admin/products/:product_id/rejection (#18)" do
    it "rejects with a reason (AC1)" do
      sign_in admin

      reject_with("รูปหน้าปัดเบลอ ขอรูปใหม่")

      expect(product.reload).to be_rejected
      expect(product.latest_rejection).to have_attributes(reviewer: admin, reason: "รูปหน้าปัดเบลอ ขอรูปใหม่")
    end

    it "requires a reason (AC2)" do
      sign_in admin

      reject_with("   ")

      expect(product.reload).to be_pending_review
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("กรุณาระบุเหตุผล")
    end

    it "forbids normal users" do
      sign_in create(:user)

      reject_with("x" * 20)

      expect(response).to have_http_status(:forbidden)
      expect(product.reload).to be_pending_review
    end
  end

  describe "minimum reason length" do
    before { sign_in admin }

    it "rejects a reason of 9 characters" do
      reject_with("ก" * 9)

      expect(product.reload).to be_pending_review
    end

    it "accepts a reason of exactly 10 characters" do
      reject_with("ก" * 10)

      expect(product.reload).to be_rejected
    end

    it "re-renders the review page with the message instead of redirecting" do
      reject_with("สั้นไป")

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("ข้อผิดพลาด: เหตุผลต้องมีอย่างน้อย 10 ตัวอักษร", product.title)
    end

    it "keeps what the admin typed and reopens the dialog" do
      reject_with("สั้นไป")

      expect(response.body).to include("สั้นไป", 'data-reject-dialog-open-value="true"')
    end

    it "does not show the failed attempt in the history or count it as a round" do
      reject_with("สั้นไป")

      html = Nokogiri::HTML(response.body)
      expect(html.css("ol li").size).to eq(2)
      expect(response.body).not_to include("ส่งใหม่ครั้งที่")
    end

    it "does not open the dialog on a normal visit" do
      get admin_product_path(product)

      expect(response.body).to include('data-reject-dialog-open-value="false"')
    end
  end

  describe "when another admin already decided" do
    it "redirects back with the status message" do
      sign_in admin
      product.update_column(:status, Product.statuses[:approved])

      reject_with("ก" * 20)

      expect(response).to redirect_to(admin_product_path(product))
      expect(flash[:alert]).to include("สถานะสินค้าเปลี่ยนไปแล้ว")
    end
  end
end
