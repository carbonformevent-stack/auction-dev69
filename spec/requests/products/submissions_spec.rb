require "rails_helper"

RSpec.describe "Products::Submissions" do
  let(:seller) { create(:user) }

  describe "POST /products/:product_id/submission (#13)" do
    it "redirects guests to sign in" do
      post product_submission_path(create(:product, :with_image))

      expect(response).to redirect_to(new_user_session_path)
    end

    context "when signed in as the seller" do
      before { sign_in seller }

      it "submits a complete draft (AC1)" do
        product = create(:product, :with_image, seller: seller)

        post product_submission_path(product)

        expect(product.reload).to be_pending_review
        expect(flash[:notice]).to include("ส่งตรวจแล้ว")
      end

      it "explains what is missing (AC2)" do
        product = create(:product, seller: seller)

        post product_submission_path(product)

        expect(product.reload).to be_draft
        expect(flash[:alert]).to include("ต้องมีรูปอย่างน้อย 1 รูป")
      end

      it "does not change an already submitted product (AC4)" do
        product = create(:product, :approved, seller: seller)

        post product_submission_path(product)

        expect(product.reload).to be_approved
      end
    end

    it "returns 404 for another user and keeps the status (AC3)" do
      product = create(:product, :with_image, seller: seller)
      sign_in create(:user)

      post product_submission_path(product)

      expect(response).to have_http_status(:not_found)
      expect(product.reload).to be_draft
    end
  end
end
