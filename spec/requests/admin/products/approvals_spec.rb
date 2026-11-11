require "rails_helper"

RSpec.describe "Admin::Products::Approvals" do
  let(:product) { create(:product, :pending_review) }

  describe "POST /admin/products/:product_id/approval (#17)" do
    it "approves and records the admin (AC1)" do
      admin = create(:user, :admin)
      sign_in admin

      post admin_product_approval_path(product)

      expect(product.reload).to be_approved
      expect(product.reviews.last.reviewer).to eq(admin)
      expect(response).to redirect_to(admin_products_path)
    end

    it "tells the second admin that the status already changed (AC3, AC4)" do
      product.update_column(:status, Product.statuses[:rejected])
      sign_in create(:user, :admin)

      post admin_product_approval_path(product)

      expect(product.reload).to be_rejected
      expect(flash[:alert]).to include("สถานะสินค้าเปลี่ยนไปแล้ว")
    end

    it "forbids normal users (AC5)" do
      sign_in create(:user)

      post admin_product_approval_path(product)

      expect(response).to have_http_status(:forbidden)
      expect(product.reload).to be_pending_review
    end
  end
end
