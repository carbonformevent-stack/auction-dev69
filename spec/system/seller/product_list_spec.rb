require "rails_helper"

RSpec.describe "Seller product list" do
  let(:seller) { create(:user, name: "ณัฐพล") }

  before do
    sign_in seller
    create(:product, seller: seller, title: "แก้วเจียระไนโบราณ")
    create(:product, :pending_review, seller: seller, title: "นาฬิกาพกเงินแท้")
    create(:product, :approved, seller: seller, title: "สร้อยทองคำเก่า")
    rejected = create(:product, :rejected, seller: seller, title: "ภาพวาดสีน้ำมันชายทะเล")
    create(:product_review, :rejected, product: rejected, reason: "รูปไม่ชัด ขอรูปด้านหลังกรอบภาพเพิ่ม")
  end

  describe "status tabs" do
    it "filters the list when a tab is chosen and marks it current" do
      visit products_path
      find("a[data-status-tab='pending_review']").click

      expect(page).to have_content("นาฬิกาพกเงินแท้")
      expect(page).to have_no_content("สร้อยทองคำเก่า")
      expect(page).to have_css("a[data-status-tab='pending_review'][aria-current='true']")
    end

    it "shows counts on each tab" do
      visit products_path

      expect(page).to have_css("a[data-status-tab='all']", text: "4")
      expect(page).to have_css("a[data-status-tab='draft']", text: "1")
    end

    it "opens a product from its row" do
      visit products_path
      click_link "สร้อยทองคำเก่า"

      expect(page).to have_css("h1", text: "สร้อยทองคำเก่า")
    end
  end

  describe "on desktop" do
    it "offers the listing button in the header and hides the bottom call to action" do
      visit products_path

      expect(page).to have_link("ลงสินค้าใหม่", count: 1)
      expect(page).to have_content("ไม่อนุมัติ")
      expect(page).to have_content("รูปไม่ชัด ขอรูปด้านหลังกรอบภาพเพิ่ม")
      snap("step4-list-desktop")
    end
  end

  describe "on mobile" do
    before { resize_to_mobile }

    it "shows the call to action pinned to the bottom and hides the desktop button" do
      visit products_path

      expect(page).to have_link("ลงสินค้าใหม่", count: 1)
      expect(page).to have_css(".fixed a", text: "ลงสินค้าใหม่")
    end

    it "uses short tab labels and hides the row details" do
      visit products_path

      expect(page).to have_link("รอตรวจ")
      expect(page).to have_no_content("แก้ไขและส่งใหม่")
    end

    it "does not scroll horizontally" do
      visit products_path
      snap("step4-list-mobile")

      expect(horizontal_overflow?).to be(false)
    end
  end

  describe "when the seller has no products" do
    it "invites the first listing" do
      sign_in create(:user)
      visit products_path

      expect(page).to have_content("ยังไม่มีสินค้า")
      expect(page).to have_link("ลงสินค้าชิ้นแรก")
      snap("step4-list-empty")
    end
  end
end
