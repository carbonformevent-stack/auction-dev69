require "rails_helper"

RSpec.describe "Admin::Products" do
  let(:admin) { create(:user, :admin) }

  describe "GET /admin/products (#16)" do
    it "redirects guests to sign in" do
      get admin_products_path

      expect(response).to redirect_to(new_user_session_path)
    end

    it "forbids normal users (AC3)" do
      sign_in create(:user)

      get admin_products_path

      expect(response).to have_http_status(:forbidden)
    end

    it "lists only pending products, oldest first, with summary data (AC1, AC2)" do
      seller = create(:user, name: "ผู้ขายหนึ่ง")
      newer = create(:product, :pending_review, title: "ส่งทีหลัง", submitted_at: 1.minute.ago)
      older = create(:product, :pending_review, title: "ส่งก่อน", seller: seller, starting_price: 4500,
                                                category: :painting, submitted_at: 1.hour.ago)
      create(:product, title: "ยังเป็นร่าง")
      sign_in admin

      get admin_products_path

      body = response.body
      expect(body.index(older.title)).to be < body.index(newer.title)
      expect(body).not_to include("ยังเป็นร่าง")
      expect(body).to include("ผู้ขายหนึ่ง", "฿4,500", "ภาพวาด", "<img")
    end

    it "shows an empty message (AC4)" do
      sign_in admin

      get admin_products_path

      expect(response.body).to include("ไม่มีสินค้ารอตรวจ")
    end
  end

  describe "GET /admin/products/:id (#17 AC2, #12 AC5, #19)" do
    it "shows every field, images, certificate, proposed duration and history with reviewers" do
      product = create(:product, :pending_review, desired_duration_minutes: 4320, description: "ล้างเครื่องแล้ว")
      product.certificate.attach(fixture_upload("certificate.pdf"))
      create(:product_review, :rejected, product: product, reviewer: create(:user, :admin, name: "สมชาย"),
                                         reason: "ขอรูปเพิ่ม")
      sign_in admin

      get admin_product_path(product)

      expect(response.body).to include(product.title, "ล้างเครื่องแล้ว", "3 วัน", "certificate.pdf",
                                       "<img", "สมชาย", "ขอรูปเพิ่ม", "อนุมัติ")
    end

    it "forbids normal users" do
      sign_in create(:user)

      get admin_product_path(create(:product, :pending_review))

      expect(response).to have_http_status(:forbidden)
    end
  end
end
