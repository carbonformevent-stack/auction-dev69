require "rails_helper"

RSpec.describe "Layout" do
  describe "header for signed in users" do
    let(:user) { create(:user, name: "ณัฐพล") }

    before { sign_in user }

    it "shows an account menu with the user's initial, product list and sign out" do
      get products_path

      expect(response.body).to include('aria-label="บัญชีของฉัน"', "ณ", "สินค้าของฉัน", "ออกจากระบบ")
    end

    it "does not offer the admin area to normal users" do
      get products_path

      expect(response.body).not_to include(admin_products_path)
    end

    it "offers the admin area to admins on user pages" do
      sign_in create(:user, :admin)

      get products_path

      expect(response.body).to include(admin_products_path)
    end
  end

  describe "header for guests" do
    it "shows only the brand without an account menu" do
      get new_user_session_path

      expect(response.body).to include("ประมูลสินค้าสะสม")
      expect(response.body).not_to include('aria-label="บัญชีของฉัน"')
    end
  end

  describe "admin header" do
    before { sign_in create(:user, :admin) }

    it "shows the admin badge and admin navigation with the queue marked current" do
      get admin_products_path

      expect(response.body).to include('aria-label="เมนูแอดมิน"', "แอดมิน", "คิวตรวจสอบ", 'aria-current="page"')
    end

    it "links back to the user area" do
      get admin_products_path

      expect(response.body).to include("กลับหน้าผู้ใช้", products_path)
    end
  end

  describe "toast notifications" do
    let(:seller) { create(:user) }

    before { sign_in seller }

    it "renders a success toast with a title, a message and a dismiss button" do
      product = create(:product, :with_image, seller: seller, title: "นาฬิกาพก")
      post product_submission_path(product)
      follow_redirect!

      expect(response.body).to include('role="status"', "ส่งตรวจสอบแล้ว", "นาฬิกาพก อยู่ในคิวของทีมตรวจสอบ")
      expect(response.body).to include('data-controller="dismiss"', 'aria-label="ปิดการแจ้งเตือน"')
    end

    it "renders failures as an alert toast" do
      product = create(:product, seller: seller)
      post product_submission_path(product)
      follow_redirect!

      expect(response.body).to include('role="alert"', "ส่งตรวจไม่ได้")
    end
  end

  describe "mobile app bar" do
    before { sign_in create(:user) }

    it "replaces the desktop header on pages that provide a mobile bar" do
      get products_path

      expect(response.body).to include('data-mobile-bar', 'aria-label="เปิดเมนู"')
    end
  end
end
