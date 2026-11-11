require "rails_helper"

# Definition of Done: ทุกหน้าที่มี UI ต้องใช้ได้ที่ความกว้างมือถือ (390px) — หน้าต้องไม่เลื่อนแนวนอน
# และปุ่มหลักที่ติดขอบล่างต้องมองเห็น (ตารางคิว Admin เลื่อนได้ในกรอบของตัวเองเท่านั้น)
RSpec.describe "Mobile layout (390px)" do
  let(:seller) { create(:user, name: "ณัฐพล") }
  let(:admin) { create(:user, :admin, name: "สมชาย แอดมิน") }

  def long_title = "นาฬิกาพกโบราณตัวเรือนเงินแท้ลายแกะสลักมือฝีมือช่างเก่า ปี 1890 สภาพสะสมหายาก"

  before { resize_to_mobile }

  context "when signed in as a seller" do
    let(:draft) { create(:product, :with_image, seller: seller, title: long_title) }
    let(:rejected) do
      create(:product, :rejected, seller: seller, title: long_title).tap do |product|
        create(:product_review, :rejected, product: product, reason: "รูปไม่ชัดและข้อมูลไม่ครบ กรุณาส่งรูปด้านหลังตัวเรือนเพิ่ม")
      end
    end

    before { sign_in seller }

    it "does not scroll sideways on the product list, even with long titles" do
      draft
      rejected

      visit products_path

      expect(horizontal_overflow?).to be(false)
    end

    it "does not scroll sideways on the new product form" do
      visit new_product_path

      expect(horizontal_overflow?).to be(false)
    end

    it "does not scroll sideways on the edit form with an image and a certificate" do
      draft.certificate.attach(fixture_upload("certificate.pdf"))

      visit edit_product_path(draft)

      expect(horizontal_overflow?).to be(false)
    end

    it "does not scroll sideways on a draft's detail page" do
      visit product_path(draft)

      expect(horizontal_overflow?).to be(false)
    end

    it "does not scroll sideways on a rejected product's detail page" do
      visit product_path(rejected)

      expect(horizontal_overflow?).to be(false)
    end

    it "keeps the primary actions pinned and visible" do
      visit product_path(rejected)
      expect(page).to have_css("[data-mobile-cta]", text: "แก้ไขและส่งใหม่", visible: :visible)

      visit new_product_path

      expect(page).to have_button("ส่งตรวจสอบ", visible: :visible)
    end

    it "replaces the desktop header with the app bar on every seller page" do
      [ products_path, new_product_path, product_path(draft), edit_product_path(draft) ].each do |path|
        visit path

        expect(page).to have_css("[data-mobile-bar]", visible: :visible)
      end
    end
  end

  context "when signed in as an admin" do
    let(:pending) do
      create(:product, :pending_review, title: long_title, seller: create(:user, name: "อรุณี สุขใจ")).tap do |product|
        product.images.attach([ image_blob("image.png"), image_blob("image.webp") ])
        product.certificate.attach(fixture_upload("certificate.pdf"))
      end
    end

    before do
      sign_in admin
      pending
    end

    it "does not scroll the queue page sideways — only the table scrolls" do
      visit admin_products_path

      expect(horizontal_overflow?).to be(false)
    end

    it "does not scroll sideways on the review page" do
      visit admin_product_path(pending)

      expect(horizontal_overflow?).to be(false)
    end

    it "pins the decision bar on the review page" do
      visit admin_product_path(pending)

      expect(page).to have_button("อนุมัติ", visible: :visible)
    end

    it "opens the reject dialog as a bottom sheet that fills the width" do
      visit admin_product_path(pending)
      click_button "ไม่อนุมัติ", match: :first

      rect = find("dialog[open]").evaluate_script("(() => { const r = this.getBoundingClientRect(); return { left: r.left, right: r.right, bottom: r.bottom }; })()")

      expect(rect).to include("left" => 0, "right" => 390)
      expect(rect["bottom"]).to be_within(1).of(page.evaluate_script("window.innerHeight"))
    end

    it "keeps the dialog usable without sideways scrolling" do
      visit admin_product_path(pending)
      click_button "ไม่อนุมัติ", match: :first
      snap("step9-reject-sheet-mobile")

      expect(horizontal_overflow?).to be(false)
    end
  end
end
