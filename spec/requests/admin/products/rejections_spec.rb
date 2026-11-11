require "rails_helper"

RSpec.describe "Admin::Products::Rejections" do
  let(:product) { create(:product, :pending_review) }
  let(:admin) { create(:user, :admin) }

  describe "POST /admin/products/:product_id/rejection (#18)" do
    it "rejects with a reason (AC1)" do
      sign_in admin

      post admin_product_rejection_path(product), params: { rejection: { reason: "รูปเบลอ" } }

      expect(product.reload).to be_rejected
      expect(product.latest_rejection).to have_attributes(reviewer: admin, reason: "รูปเบลอ")
    end

    it "requires a reason (AC2)" do
      sign_in admin

      post admin_product_rejection_path(product), params: { rejection: { reason: "   " } }

      expect(product.reload).to be_pending_review
      expect(flash[:alert]).to eq("กรุณาระบุเหตุผล")
    end

    it "forbids normal users" do
      sign_in create(:user)

      post admin_product_rejection_path(product), params: { rejection: { reason: "x" } }

      expect(response).to have_http_status(:forbidden)
      expect(product.reload).to be_pending_review
    end
  end
end
