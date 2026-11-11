require "rails_helper"

RSpec.describe "Seller product detail" do
  let(:seller) { create(:user) }
  let(:admin) { create(:user, :admin, name: "สมชาย แอดมิน") }

  before { sign_in seller }

  describe "gallery" do
    let(:product) do
      create(:product, seller: seller, title: "ตลับเงินโบราณ").tap do |built|
        built.images.attach([ image_blob("image.jpg"), image_blob("image.png"), image_blob("image.webp") ])
      end
    end

    it "updates the counter and the current thumbnail when a thumbnail is chosen" do
      visit product_path(product)
      expect(page).to have_css("[data-gallery-target='counter']", text: "1 / 3")

      find("a[aria-label='ดูรูปที่ 2']").click

      expect(page).to have_css("[data-gallery-target='counter']", text: "2 / 3")
      expect(page).to have_css("a[aria-label='ดูรูปที่ 2'][aria-current='true']")
    end

    it "shows the chosen image as the main image" do
      visit product_path(product)
      second = find("a[aria-label='ดูรูปที่ 2']")

      second.click

      expect(page).to have_css("[data-gallery-target='counter']", text: "2 / 3")
      expect(find("[data-gallery-target='main']")[:src]).to eq(second[:href])
    end

    it "keeps only one thumbnail marked as current" do
      visit product_path(product)

      find("a[aria-label='ดูรูปที่ 3']").click

      expect(page).to have_css("a[aria-current='true']", count: 1)
    end
  end

  describe "a rejected product" do
    let(:product) do
      create(:product, :rejected, seller: seller, title: "ภาพวาดชายทะเล").tap do |rejected|
        create(:product_review, :rejected, product: rejected, reviewer: admin, reason: "รูปไม่ชัด ขอรูปด้านหลังกรอบภาพเพิ่ม")
      end
    end

    it "shows the reason and leads to the edit form from the banner" do
      visit product_path(product)
      expect(page).to have_css("[role='alert']", text: "รูปไม่ชัด ขอรูปด้านหลังกรอบภาพเพิ่ม")
      snap("step6-detail-rejected-desktop")

      click_link "แก้ไขและส่งใหม่"

      expect(page).to have_css("h1", text: "แก้ไขสินค้า")
    end

    it "never shows who reviewed it" do
      visit product_path(product)

      expect(page).to have_no_content("สมชาย แอดมิน")
    end
  end

  describe "on mobile" do
    let(:product) do
      create(:product, :rejected, seller: seller, title: "ภาพวาดชายทะเล").tap do |rejected|
        create(:product_review, :rejected, product: rejected, reviewer: admin, reason: "รูปไม่ชัด")
      end
    end

    before { resize_to_mobile }

    it "pins the fix button at the bottom and hides the summary card" do
      visit product_path(product)

      expect(page).to have_css("[data-mobile-cta]", text: "แก้ไขและส่งใหม่")
      expect(page).to have_no_content("ข้อมูลการลงสินค้า")
    end

    it "puts the status badge above the title" do
      visit product_path(product)

      badge_top = find("span", text: "ไม่อนุมัติ", match: :first).evaluate_script("this.getBoundingClientRect().top")
      title_top = find("h1").evaluate_script("this.getBoundingClientRect().top")

      expect(badge_top).to be < title_top
    end

    it "does not scroll horizontally" do
      visit product_path(product)
      snap("step6-detail-rejected-mobile")

      expect(horizontal_overflow?).to be(false)
    end
  end

  describe "a pending product" do
    it "explains the wait and offers no actions" do
      pending_product = create(:product, :pending_review, seller: seller)
      visit product_path(pending_product)

      expect(page).to have_content("อยู่ระหว่างตรวจสอบ")
      expect(page).to have_no_link("แก้ไข")
    end
  end
end
