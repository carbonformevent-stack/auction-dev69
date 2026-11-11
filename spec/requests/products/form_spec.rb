require "rails_helper"

RSpec.describe "Product form" do
  let(:seller) { create(:user) }

  let(:valid_params) do
    { product: { category: "watch", starting_price: 1000, title: "นาฬิกาพก", description: "สภาพดี",
                 desired_duration_minutes: 4320 } }
  end

  before { sign_in seller }

  describe "GET /products/new" do
    before { get new_product_path }

    it "shows the five step bar" do
      expect(response.body).to include('aria-label="ขั้นตอน"', "ประเภท", "รายละเอียด", "รูปภาพ", "ใบรับรอง", "ราคาและเวลา")
    end

    it "offers the four categories as radio tiles" do
      expect(response.body.scan(/<input[^>]*type="radio"[^>]*>/).size).to eq(4)
      expect(response.body).to include("นาฬิกา", "เครื่องประดับ", "หนังสือเก่า", "ภาพวาด")
    end

    it "labels the fields as in the design" do
      expect(response.body).to include("ประเภทสินค้า", "ชื่อสินค้า", "รายละเอียดสินค้า", "ราคาเริ่มต้น", "ระยะเวลาที่ต้องการ")
      expect(response.body).to include("Admin เป็นผู้กำหนดวัน-เวลาจริง", "ไม่บังคับ")
    end

    it "shows live character counters with their limits" do
      expect(response.body).to include("0/150", "0/5,000", 'data-controller="char-counter"')
    end

    it "offers 5 days as a duration" do
      expect(response.body).to include(">5 วัน<")
    end

    it "shows the readiness summary and the FPSBA note beside the form" do
      expect(response.body).to include("ความพร้อมในการส่ง", "0/5", "ประมูลแบบปิดผนึก (FPSBA)")
    end

    it "puts save draft before submit so Enter never submits for review" do
      expect(response.body.index("บันทึกฉบับร่าง")).to be < response.body.index("ส่งตรวจสอบ")
    end

    it "shows the mobile step summary" do
      expect(response.body).to include("ขั้นที่ 1 จาก 5", 'role="progressbar"')
    end
  end

  describe "GET /products/:id/edit" do
    it "shows each saved image with a delete button and marks the first as the cover" do
      product = create(:product, :with_image, seller: seller)

      get edit_product_path(product)

      expect(response.body).to include('aria-label="ลบรูป image.jpg"', "ปก", product_image_path(product, product.images.first))
    end

    it "shows readiness for a draft whose only open step is the optional certificate" do
      product = create(:product, :with_image, seller: seller)

      get edit_product_path(product)

      expect(response.body).to include("4/5", "ขั้นที่ 4 จาก 5 · ใบรับรอง")
    end

    it "shows the attached certificate with its size and a delete button" do
      product = create(:product, :with_image, seller: seller)
      product.certificate.attach(fixture_upload("certificate.pdf"))

      get edit_product_path(product)

      expect(response.body).to include("certificate.pdf", 'aria-label="ลบไฟล์ใบรับรอง"', product_certificate_path(product))
    end

    it "offers to attach a certificate when there is none" do
      get edit_product_path(create(:product, seller: seller))

      expect(response.body).to include("แนบไฟล์ PDF")
    end

    it "shows the current status of a rejected product" do
      get edit_product_path(create(:product, :rejected, seller: seller))

      expect(response.body).to include("ไม่อนุมัติ", "แก้ไขสินค้า")
    end
  end

  describe "inline errors" do
    it "marks the invalid field and prefixes its message" do
      post products_path, params: valid_params.deep_merge(product: { starting_price: 0 })

      expect(response.body).to include('aria-invalid="true"', "ข้อผิดพลาด: ราคาต้องอยู่ระหว่าง 1–20,000 บาท")
    end
  end

  describe "POST /products with submit_for_review" do
    let(:submit_params) do
      valid_params.deep_merge(product: { images: [ fixture_upload("image.jpg") ] }).merge(submit_for_review: "1")
    end

    it "creates the product and sends it straight to review" do
      expect { post products_path, params: submit_params }.to change(Product, :count).by(1)

      expect(Product.last).to be_pending_review
      expect(Product.last.submitted_at).to be_present
    end

    it "returns to the list with a confirmation" do
      post products_path, params: submit_params

      expect(response).to redirect_to(products_path)
      expect(flash[:notice]).to include("ส่งตรวจสอบแล้ว", "นาฬิกาพก")
    end

    it "creates nothing and explains what is missing when there are no images" do
      expect { post products_path, params: valid_params.merge(submit_for_review: "1") }.not_to change(Product, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("ต้องมีรูปอย่างน้อย 1 รูป")
    end

    it "only saves a draft without the submit button" do
      params = valid_params.deep_merge(product: { images: [ fixture_upload("image.jpg") ] })

      post products_path, params: params

      expect(Product.last).to be_draft
      expect(response).to redirect_to(product_path(Product.last))
    end
  end

  describe "PATCH /products/:id with submit_for_review" do
    it "saves the edits and resubmits a rejected product" do
      product = create(:product, :rejected, seller: seller)

      patch product_path(product), params: { product: { title: "แก้ตามที่ขอ" }, submit_for_review: "1" }

      expect(product.reload).to have_attributes(title: "แก้ตามที่ขอ", status: "pending_review")
      expect(response).to redirect_to(products_path)
    end

    it "changes nothing when the new data is invalid" do
      product = create(:product, :rejected, seller: seller)

      patch product_path(product), params: { product: { title: "ชื่อใหม่", starting_price: 0 }, submit_for_review: "1" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(product.reload).to have_attributes(status: "rejected", title: product.title)
    end

    it "keeps a rejected product rejected when only saving" do
      product = create(:product, :rejected, seller: seller)

      patch product_path(product), params: { product: { title: "แก้แล้ว" } }

      expect(product.reload).to be_rejected
    end
  end
end
