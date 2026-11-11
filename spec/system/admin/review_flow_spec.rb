require "rails_helper"

RSpec.describe "Admin review flow" do
  let(:admin) { create(:user, :admin, name: "สมชาย แอดมิน") }
  let(:seller) { create(:user, name: "อรุณี สุขใจ") }
  let(:product) do
    create(:product, :pending_review, seller: seller, title: "นาฬิกาพกเงินแท้", category: :watch).tap do |built|
      built.images.attach([ image_blob("image.png"), image_blob("image.webp") ])
      built.certificate.attach(fixture_upload("certificate.pdf"))
    end
  end

  before { sign_in admin }

  describe "inspecting the product" do
    it "shows the queue position, the gallery, the certificate and the seller" do
      visit admin_product_path(product)

      expect(page).to have_link("← คิวรอตรวจสอบ (1 จาก 1)")
      expect(page).to have_css("h2", text: "certificate.pdf")
      expect(page).to have_css("section", text: "อรุณี สุขใจ")
      snap("step8-review-desktop")
    end

    it "switches the main image from the thumbnails" do
      visit admin_product_path(product)

      find("a[aria-label='ดูรูปที่ 3']").click

      expect(page).to have_css("[data-gallery-target='counter']", text: "3 / 3")
    end

    it "keeps the full size link pointing at the chosen image" do
      visit admin_product_path(product)
      third = find("a[aria-label='ดูรูปที่ 3']")

      third.click

      expect(find("a[data-gallery-target='full']")[:href]).to eq(third[:href])
    end
  end

  describe "approving" do
    it "approves with one click and no browser confirmation" do
      visit admin_product_path(product)

      click_button "อนุมัติ"

      expect(page).to have_css("[role='status']", text: "อนุมัติ")
      expect(product.reload).to be_approved
    end
  end

  describe "the reject dialog" do
    before { visit admin_product_path(product) }

    def open_dialog = click_button("ไม่อนุมัติ", match: :first)

    it "opens from the decision bar" do
      open_dialog

      expect(page).to have_css("dialog[open]", text: "ไม่อนุมัติสินค้านี้")
      snap("step8-reject-dialog-desktop")
    end

    it "keeps the confirm button disabled until the reason reaches 10 characters" do
      open_dialog
      confirm = find_button("ยืนยันไม่อนุมัติ", disabled: :all)
      expect(confirm).to be_disabled

      fill_in "rejection[reason]", with: "ก" * 9
      expect(find_button("ยืนยันไม่อนุมัติ", disabled: :all)).to be_disabled

      fill_in "rejection[reason]", with: "ก" * 10
      expect(page).to have_button("ยืนยันไม่อนุมัติ", disabled: false)
    end

    it "tells how many characters are still missing" do
      open_dialog

      fill_in "rejection[reason]", with: "สั้น"

      expect(page).to have_css("#reject-dialog-counter", text: "ต้องกรอกเหตุผลอย่างน้อย 10 ตัวอักษร (ตอนนี้ 4)")
    end

    it "appends a common reason to what is already typed" do
      open_dialog
      fill_in "rejection[reason]", with: "ขอรูปด้านหลังตัวเรือน"

      click_button "+ รูปไม่ชัด"

      expect(find_field("rejection[reason]").value).to eq("ขอรูปด้านหลังตัวเรือน\nรูปไม่ชัด")
    end

    it "can be filled with a single shortcut when it is long enough" do
      open_dialog

      click_button "+ ใบรับรองไม่ตรงกับสินค้า"

      expect(page).to have_button("ยืนยันไม่อนุมัติ", disabled: false)
    end

    it "closes without rejecting when cancelled" do
      open_dialog

      click_button "ยกเลิก"

      expect(page).to have_no_css("dialog[open]")
      expect(product.reload).to be_pending_review
    end

    it "rejects and returns to the queue with the reason saved for the seller" do
      open_dialog
      fill_in "rejection[reason]", with: "ใบรับรองไม่ตรงกับสินค้า ขอเอกสารฉบับจริง"

      click_button "ยืนยันไม่อนุมัติ"

      expect(page).to have_current_path(admin_products_path)
      expect(product.reload.latest_rejection.reason).to eq("ใบรับรองไม่ตรงกับสินค้า ขอเอกสารฉบับจริง")
    end
  end

  describe "when the server refuses a short reason" do
    it "reopens the dialog with the text kept, even if the browser check was bypassed" do
      visit admin_product_path(product)
      click_button "ไม่อนุมัติ", match: :first
      fill_in "rejection[reason]", with: "ก" * 10
      page.execute_script("document.querySelector('textarea[name=\"rejection[reason]\"]').removeAttribute('minlength')")
      page.execute_script("document.querySelector('textarea[name=\"rejection[reason]\"]').value = 'สั้นไป'")
      page.execute_script("document.querySelector('[data-reject-dialog-target=submit]').disabled = false")

      click_button "ยืนยันไม่อนุมัติ"

      expect(page).to have_css("dialog[open] .field-error", text: "เหตุผลต้องมีอย่างน้อย 10 ตัวอักษร")
      expect(find_field("rejection[reason]").value).to eq("สั้นไป")
    end
  end

  describe "a decided product" do
    it "has no decision bar and shows the result" do
      decided = create(:product, :rejected, title: "ภาพวาดที่ตีกลับ")
      create(:product_review, :rejected, product: decided, reviewer: admin, reason: "รูปไม่ชัด ขอรูปเพิ่ม")

      visit admin_product_path(decided)

      expect(page).to have_no_button("อนุมัติ")
      expect(page).to have_content("ไม่อนุมัติแล้ว")
    end
  end
end
