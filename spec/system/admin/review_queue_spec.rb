require "rails_helper"

RSpec.describe "Admin review queue" do
  let(:admin) { create(:user, :admin, name: "สมชาย แอดมิน") }

  before do
    sign_in admin
    create(:product, :pending_review, title: "นาฬิกาพกเงินแท้", category: :watch,
                                      seller: create(:user, name: "อรุณี สุขใจ"), submitted_at: 3.hours.ago)
    create(:product, :pending_review, title: "ภาพวาดสีน้ำมันชายทะเล", category: :painting, starting_price: 15_000,
                                      submitted_at: 70.hours.ago)
    resubmitted = create(:product, :pending_review, title: "แหวนทองโบราณ", category: :jewelry, submitted_at: 1.hour.ago)
    create(:product_review, :rejected, product: resubmitted, created_at: 2.days.ago)
  end

  describe "the queue" do
    it "shows the stat cards, the oldest waiting product first and the resubmission mark" do
      visit admin_products_path

      expect(page).to have_css("[data-stat='pending']", text: "3")
      expect(page).to have_css("[data-stat='overdue']", text: "1")
      expect(page).to have_content("ส่งใหม่ครั้งที่ 2")
      snap("step7-queue-desktop")
    end

    it "lists the product waiting longest at the top" do
      visit admin_products_path

      titles = all("tbody tr").map { |row| row.find("a", match: :first).text }

      expect(titles.first).to eq("ภาพวาดสีน้ำมันชายทะเล")
    end

    it "marks only the overdue row in red" do
      visit admin_products_path

      expect(page).to have_css("tr[data-overdue='true']", count: 1)
      expect(find("tr[data-overdue='true']")).to have_text("ภาพวาดสีน้ำมันชายทะเล")
    end
  end

  describe "category chips" do
    it "narrows the queue and marks the chosen chip" do
      visit admin_products_path
      find("a[data-category-chip='painting']").click

      expect(page).to have_css("tbody tr", count: 1)
      expect(page).to have_css("a[data-category-chip='painting'][aria-current='true']")
    end

    it "explains when no product of that category is waiting" do
      visit admin_products_path
      find("a[data-category-chip='old_book']").click

      expect(page).to have_content("ไม่มีสินค้าประเภทนี้ในคิว")
    end
  end

  describe "opening a product" do
    it "leads to the review page from the row button" do
      visit admin_products_path

      click_link "ตรวจสอบ นาฬิกาพกเงินแท้"

      expect(page).to have_css("h1", text: "นาฬิกาพกเงินแท้")
    end
  end

  describe "admin navigation" do
    it "marks the queue as the current page in the admin header" do
      visit admin_products_path

      expect(page).to have_css("nav[aria-label='เมนูแอดมิน'] a[aria-current='page']", text: "คิวตรวจสอบ")
      expect(page).to have_css("header", text: "แอดมิน")
    end

    it "sends /admin to the queue" do
      visit admin_root_path

      expect(page).to have_current_path(admin_products_path)
    end
  end

  describe "on a phone" do
    it "keeps the page itself from scrolling sideways — only the table scrolls" do
      resize_to_mobile
      visit admin_products_path
      snap("step7-queue-mobile")

      expect(horizontal_overflow?).to be(false)
    end
  end
end
