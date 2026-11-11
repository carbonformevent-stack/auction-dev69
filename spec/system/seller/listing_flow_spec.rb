require "rails_helper"

RSpec.describe "Seller listing flow" do
  let(:seller) { create(:user) }
  let(:image_path) { Rails.root.join("spec/fixtures/files/image.jpg") }
  let(:pdf_path) { Rails.root.join("spec/fixtures/files/certificate.pdf") }

  before { sign_in seller }

  def fill_required_fields(title: "นาฬิกาพกเงินแท้")
    choose "นาฬิกา", allow_label_click: true
    fill_in "ชื่อสินค้า", with: title
    fill_in "รายละเอียดสินค้า", with: "สภาพดี ใช้งานได้ปกติ"
    fill_in "ราคาเริ่มต้น", with: "2500"
  end

  describe "creating a product" do
    it "uploads an image and sends the product to review in one step" do
      visit new_product_path
      fill_required_fields
      attach_file "เลือกไฟล์รูปสินค้า", image_path

      click_button "ส่งตรวจสอบ"

      expect(page).to have_css("[role='status']", text: "ส่งตรวจสอบแล้ว")
      expect(page).to have_css("a[data-status-tab='pending_review']", text: "1")
      expect(Product.last).to be_pending_review
    end

    it "tells the seller which file was chosen before saving" do
      visit new_product_path

      attach_file "เลือกไฟล์รูปสินค้า", image_path

      expect(page).to have_content("เลือกแล้ว: image.jpg")
    end

    it "saves a draft without submitting" do
      visit new_product_path
      fill_required_fields

      click_button "บันทึกฉบับร่าง"

      expect(page).to have_css("[role='status']", text: "บันทึกสินค้าแบบร่างแล้ว")
      expect(Product.last).to be_draft
    end

    it "treats Enter in a text field as save draft, never as submit for review" do
      visit new_product_path
      fill_required_fields
      attach_file "เลือกไฟล์รูปสินค้า", image_path

      find_field("ชื่อสินค้า").send_keys(:enter)

      expect(page).to have_css("[role='status']", text: "บันทึกสินค้าแบบร่างแล้ว")
      expect(Product.last).to be_draft
    end

    it "keeps everything and explains the missing image when submitting without one" do
      visit new_product_path
      fill_required_fields

      click_button "ส่งตรวจสอบ"

      expect(page).to have_css("#images-errors", text: "ต้องมีรูปอย่างน้อย 1 รูป")
      expect(page).to have_field("ชื่อสินค้า", with: "นาฬิกาพกเงินแท้")
      expect(Product.count).to eq(0)
    end

    it "marks an invalid price and keeps what was typed" do
      visit new_product_path
      fill_required_fields
      page.execute_script("document.getElementById('product-form').noValidate = true")
      fill_in "ราคาเริ่มต้น", with: "20001"

      click_button "บันทึกฉบับร่าง"

      expect(page).to have_css("input[aria-invalid='true']#product_starting_price")
      expect(page).to have_content("ข้อผิดพลาด: ราคาต้องอยู่ระหว่าง 1–20,000 บาท")
    end
  end

  describe "character counters" do
    it "update as the seller types and warn at the limit" do
      visit new_product_path

      fill_in "ชื่อสินค้า", with: "abc"
      expect(page).to have_css("[data-char-counter-target='count']", text: "3/150")

      fill_in "ชื่อสินค้า", with: "ก" * 150
      expect(page).to have_css(".text-danger[data-char-counter-target='count']", text: "150/150 ครบแล้ว")
    end
  end

  describe "editing a product" do
    let(:product) { create(:product, :with_image, seller: seller, title: "แหวนทองโบราณ") }

    it "deletes an image with the button that lives outside the main form" do
      visit edit_product_path(product)

      accept_confirm { click_button "ลบรูป image.jpg" }

      expect(page).to have_css("[role='status']", text: "ลบรูปแล้ว")
      expect(product.reload.images.count).to eq(0)
    end

    it "attaches a certificate and shows the chosen file name" do
      visit edit_product_path(product)
      attach_file "เลือกไฟล์ใบรับรอง PDF", pdf_path
      expect(page).to have_content("เลือกแล้ว: certificate.pdf")

      click_button "บันทึกฉบับร่าง"

      expect(page).to have_css("[role='status']", text: "บันทึกการแก้ไขแล้ว")
      expect(product.reload.certificate).to be_attached
    end

    it "removes the certificate with the button that lives outside the main form" do
      product.certificate.attach(fixture_upload("certificate.pdf"))
      visit edit_product_path(product)

      accept_confirm { click_button "ลบไฟล์ใบรับรอง" }

      expect(page).to have_css("[role='status']", text: "ลบใบรับรองแล้ว")
      expect(product.reload.certificate).not_to be_attached
    end

    it "resubmits a rejected product after fixing it" do
      rejected = create(:product, :rejected, seller: seller, title: "ภาพวาดชายทะเล")
      visit edit_product_path(rejected)

      fill_in "ชื่อสินค้า", with: "ภาพวาดชายทะเล (แก้รูปแล้ว)"
      click_button "ส่งตรวจสอบ"

      expect(page).to have_current_path(products_path)
      expect(rejected.reload).to be_pending_review
    end
  end

  describe "layout" do
    it "shows the steps, readiness summary and action bar on desktop" do
      create(:product, :with_image, seller: seller)
      visit edit_product_path(Product.last)

      expect(page).to have_css("ol[aria-label='ขั้นตอน']")
      expect(page).to have_content("ความพร้อมในการส่ง")
      expect(page).to have_button("ส่งตรวจสอบ")
      snap("step5-form-edit-desktop")
    end

    it "shows the step summary instead of the readiness sidebar on mobile" do
      resize_to_mobile
      visit new_product_path

      expect(page).to have_content("ขั้นที่ 1 จาก 5 · ประเภท")
      expect(page).to have_no_content("ความพร้อมในการส่ง")
    end

    it "pins the action bar on mobile without horizontal scroll" do
      resize_to_mobile
      visit new_product_path

      expect(page).to have_button("ส่งตรวจสอบ")
      expect(horizontal_overflow?).to be(false)
      snap("step5-form-new-mobile")
    end
  end
end
