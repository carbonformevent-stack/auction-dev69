require "rails_helper"

RSpec.describe "Layout in a browser" do
  let(:user) { create(:user, name: "ณัฐพล") }

  before { sign_in user }

  describe "account menu" do
    it "stays closed until the avatar is pressed, then offers sign out" do
      visit products_path

      expect(page).to have_no_button("ออกจากระบบ")

      find("summary[aria-label='บัญชีของฉัน']").click

      expect(page).to have_button("ออกจากระบบ")
      expect(page).to have_link("สินค้าของฉัน", href: products_path, minimum: 1)
    end
  end

  describe "toast" do
    it "appears after submitting a product and disappears when dismissed" do
      product = create(:product, :with_image, seller: user, title: "นาฬิกาพก")

      visit product_path(product)
      click_button "ส่งตรวจ"

      toast = find("[role='status'][data-controller='dismiss']")
      expect(toast).to have_text("ส่งตรวจสอบแล้ว")
      expect(toast).to have_text("นาฬิกาพก อยู่ในคิวของทีมตรวจสอบ")

      click_button "ปิดการแจ้งเตือน"

      expect(page).to have_no_css("[data-controller='dismiss']")
    end
  end

  describe "mobile" do
    before { resize_to_mobile }

    it "swaps the desktop header for the app bar on the product list" do
      visit products_path

      expect(page).to have_css("[data-mobile-bar]")
      expect(page).to have_no_css("header", visible: :visible)
      expect(page).to have_css("[data-mobile-bar]", text: "สินค้าของฉัน")
    end

    it "opens the menu from the burger button" do
      visit products_path

      find("summary[aria-label='เปิดเมนู']").click

      expect(page).to have_button("ออกจากระบบ")
    end

    it "does not scroll horizontally" do
      visit products_path

      expect(horizontal_overflow?).to be(false)
    end
  end

  describe "screenshots" do
    it "captures the seller list on desktop and mobile for review" do
      create(:product, :approved, seller: user, title: "นาฬิกาพกโบราณ")
      visit products_path
      snap("step3-products-desktop")
      resize_to_mobile
      visit products_path
      snap("step3-products-mobile")

      expect(File).to exist(Rails.root.join("tmp/screenshots/step3-products-mobile.png"))
    end
  end
end
