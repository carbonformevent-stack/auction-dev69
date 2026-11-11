require "rails_helper"

RSpec.describe "Products" do
  let(:seller) { create(:user) }
  let(:other) { create(:user) }

  let(:valid_params) do
    { product: { category: "watch", starting_price: 1000, title: "นาฬิกาพก", description: "สภาพดี",
                 desired_duration_minutes: 4320 } }
  end

  describe "guest access" do
    it "redirects to sign in" do
      get products_path

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "GET /products (#14)" do
    before { sign_in seller }

    it "shows only the current seller's products (AC1)" do
      create_list(:product, 3, seller: seller)
      create_list(:product, 2, seller: other, title: "ของคนอื่น")

      get products_path

      expect(response.body.scan("นาฬิกาพกโบราณ").size).to eq(3)
      expect(response.body).not_to include("ของคนอื่น")
    end

    it "shows a badge for every status (AC2)" do
      create(:product, seller: seller)
      %i[pending_review approved rejected].each { |status| create(:product, status, seller: seller) }

      get products_path

      %w[ร่าง รอตรวจ อนุมัติแล้ว ไม่อนุมัติ].each { |label| expect(response.body).to include(label) }
    end

    it "shows an empty state with a listing button (AC4)" do
      get products_path

      expect(response.body).to include("ยังไม่มีสินค้า")
      expect(response.body).to include(new_product_path)
    end
  end

  describe "GET /products status tabs" do
    before do
      sign_in seller
      create(:product, seller: seller, title: "ร่างหนึ่ง")
      create(:product, :pending_review, seller: seller, title: "รอตรวจหนึ่ง")
      create(:product, :approved, seller: seller, title: "อนุมัติหนึ่ง")
      create_list(:product, 2, :rejected, seller: seller, title: "ตีกลับหนึ่ง")
      create(:product, :pending_review, seller: other, title: "ของคนอื่น")
    end

    it "offers a tab per status with counts for the current seller only" do
      get products_path

      expect(response.body).to include('aria-label="กรองตามสถานะ"')
      expect(response.body.scan(/data-status-tab="(\w+)" data-count="(\d+)"/))
        .to eq([ %w[all 5], %w[draft 1], %w[pending_review 1], %w[approved 1], %w[rejected 2] ])
    end

    it "marks the all tab as current by default" do
      get products_path

      expect(response.body).to match(/aria-current="true"[^>]*data-status-tab="all"|data-status-tab="all"[^>]*aria-current="true"/)
    end

    it "filters by status and marks that tab current" do
      get products_path(status: "rejected")

      expect(response.body.scan('alt="ตีกลับหนึ่ง"').size).to eq(2)
      expect(response.body).not_to include("ร่างหนึ่ง", "อนุมัติหนึ่ง")
      expect(response.body).to match(/aria-current="true"[^>]*data-status-tab="rejected"|data-status-tab="rejected"[^>]*aria-current="true"/)
    end

    it "ignores an unknown status and shows everything" do
      get products_path(status: "hacked")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("ร่างหนึ่ง", "อนุมัติหนึ่ง")
    end

    it "ignores a non-string status parameter" do
      get products_path, params: { status: { "a" => "b" } }

      expect(response).to have_http_status(:ok)
    end

    it "explains an empty filter and keeps the tabs" do
      seller.products.where(status: :approved).destroy_all

      get products_path(status: "approved")

      expect(response.body).to include("ไม่มีสินค้าในสถานะนี้", "ลองเลือกสถานะอื่น หรือลงสินค้าใหม่", 'aria-label="กรองตามสถานะ"')
    end
  end

  describe "GET /products rows" do
    before { sign_in seller }

    it "shows a status specific action on every row" do
      create(:product, seller: seller)
      create(:product, :pending_review, seller: seller)
      create(:product, :rejected, seller: seller)

      get products_path

      expect(response.body).to include("แก้ไขต่อ", "ดูรายละเอียด", "แก้ไขและส่งใหม่")
    end

    it "shows the rejection reason in the row" do
      product = create(:product, :rejected, seller: seller)
      create(:product_review, :rejected, product: product, reason: "รูปหน้าปัดเบลอ")

      get products_path

      expect(response.body).to include("ไม่อนุมัติ", "รูปหน้าปัดเบลอ")
    end

    it "loads reviews with a single query however many products there are" do
      create_list(:product, 3, :rejected, seller: seller)
      queries = []
      counter = ->(*, payload) { queries << payload[:sql] if payload[:sql].include?('FROM "product_reviews"') }

      ActiveSupport::Notifications.subscribed(counter, "sql.active_record") { get products_path }

      expect(queries.size).to be <= 1
    end

    it "does not show the tabs when the seller has no products at all" do
      get products_path

      expect(response.body).not_to include('aria-label="กรองตามสถานะ"')
    end

    it "shows the first-listing empty state" do
      get products_path

      expect(response.body).to include("ยังไม่มีสินค้า", "ลงสินค้าชิ้นแรก", "ทีมผู้เชี่ยวชาญจะตรวจสอบก่อนนำไปจัดประมูล")
    end

    it "offers the listing button both in the header and as the mobile call to action" do
      create(:product, seller: seller)

      get products_path

      expect(response.body.scan(%r{href="#{Regexp.escape(new_product_path)}"}).size).to eq(2)
    end
  end

  describe "GET /products/:id" do
    before { sign_in seller }

    it "returns 404 for another user's product" do
      get product_path(create(:product, seller: other))

      expect(response).to have_http_status(:not_found)
    end

    it "shows the latest rejection reason without the admin's identity (#14 AC3, #18 AC3, #19 AC3)" do
      admin = create(:user, :admin, name: "สมชาย แอดมิน")
      product = create(:product, :rejected, seller: seller)
      create(:product_review, :rejected, product: product, reviewer: admin, reason: "เก่า", created_at: 2.days.ago)
      create(:product_review, :rejected, product: product, reviewer: admin, reason: "ขอรูปกลไก", created_at: 1.day.ago)

      get product_path(product)

      expect(response.body).to include("ขอรูปกลไก")
      expect(response.body).not_to include("สมชาย แอดมิน")
    end
  end

  describe "GET /products/:id page (seller view)" do
    let(:admin) { create(:user, :admin, name: "สมชาย แอดมิน") }

    before { sign_in seller }

    it "shows a rejected product with the reason in quotes, the date in Buddhist era and a fix button" do
      product = create(:product, :rejected, seller: seller)
      create(:product_review, :rejected, product: product, reviewer: admin, reason: "ขอรูปกลไก")

      get product_path(product)

      expect(response.body).to include('role="alert"', "ไม่อนุมัติ — กรุณาแก้ไขแล้วส่งใหม่", "“ขอรูปกลไก”", "แก้ไขและส่งใหม่")
      expect(response.body).to include(edit_product_path(product), "#{Time.current.year + 543}")
    end

    it "still offers the fix button when a rejected product has no review record" do
      product = create(:product, :rejected, seller: seller)

      get product_path(product)

      expect(response.body).to include("ไม่อนุมัติ — กรุณาแก้ไขแล้วส่งใหม่", edit_product_path(product))
    end

    it "does not offer a separate resubmit button for a rejected product" do
      product = create(:product, :rejected, seller: seller)

      get product_path(product)

      expect(response.body).not_to include(product_submission_path(product))
    end

    it "explains a pending product and offers no editing" do
      product = create(:product, :pending_review, seller: seller)

      get product_path(product)

      expect(response.body).to include("อยู่ระหว่างตรวจสอบ", "1–2 วันทำการ", "แก้ไขสินค้าไม่ได้")
      expect(response.body).not_to include(edit_product_path(product))
    end

    it "explains an approved product without promising an email" do
      get product_path(create(:product, :approved, seller: seller))

      expect(response.body).to include("อนุมัติแล้ว — แก้ไขไม่ได้", "รอ Admin กำหนดวัน-เวลาประมูล")
      expect(response.body).not_to include("อีเมล")
    end

    it "keeps submit, edit and delete for a draft" do
      product = create(:product, :with_image, seller: seller)

      get product_path(product)

      expect(response.body).to include(product_submission_path(product), edit_product_path(product), "ลบ")
    end

    it "shows the gallery with a counter and one thumbnail link per image" do
      product = create(:product, seller: seller)
      product.images.attach([ image_blob, image_blob ])

      get product_path(product)

      expect(response.body).to include("1 / 2", 'aria-label="ดูรูปที่ 1"', 'aria-label="ดูรูปที่ 2"', 'data-controller="gallery"')
    end

    it "says so when there are no images yet" do
      get product_path(create(:product, seller: seller))

      expect(response.body).to include("ยังไม่มีรูป")
    end

    it "shows the summary without the admin only row and the draft hint" do
      get product_path(create(:product, :pending_review, seller: seller))

      expect(response.body).to include("ข้อมูลการลงสินค้า", "ไม่ได้แนบ", "รายละเอียดสินค้า")
      expect(response.body).not_to include("(ค่าแนะนำ)", "ส่งตรวจล่าสุด")
    end

    it "shows the status history without the reviewer's identity" do
      product = create(:product, :rejected, seller: seller)
      create(:product_review, :rejected, product: product, reviewer: admin, reason: "ขอรูปกลไก")

      get product_path(product)

      expect(response.body).to include("ประวัติสถานะ", "สร้างฉบับร่าง", "ส่งตรวจสอบ")
      expect(response.body).not_to include("สมชาย แอดมิน")
    end

    it "provides the mobile app bar with a back link and a pinned call to action for rejected products" do
      get product_path(create(:product, :rejected, seller: seller))

      expect(response.body).to include("data-mobile-bar", 'aria-label="กลับ"', "รายละเอียดสินค้า", "data-mobile-cta")
    end

    it "pins no call to action for a pending product" do
      get product_path(create(:product, :pending_review, seller: seller))

      expect(response.body).not_to include("data-mobile-cta")
    end
  end

  describe "form pages" do
    before { sign_in seller }

    it "renders the new form" do
      get new_product_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("ลงสินค้าใหม่")
    end

    it "renders the edit form with existing images" do
      product = create(:product, :with_image, seller: seller)

      get edit_product_path(product)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("ลบรูป")
    end

    it "redirects away from editing a pending product" do
      product = create(:product, :pending_review, seller: seller)

      get edit_product_path(product)

      expect(response).to redirect_to(product_path(product))
    end
  end

  describe "POST /products (#9)" do
    before { sign_in seller }

    it "creates a draft owned by the current user (AC1)" do
      expect { post products_path, params: valid_params }.to change(Product, :count).by(1)

      product = Product.last
      expect(product).to have_attributes(seller: seller, status: "draft", desired_duration_minutes: 4320)
      expect(response).to redirect_to(product_path(product))
    end

    it "ignores a seller_id or status sent by the client" do
      post products_path, params: valid_params.deep_merge(product: { seller_id: other.id, status: "approved" })

      expect(Product.last).to have_attributes(seller: seller, status: "draft")
    end

    it "re-renders the form with errors for an invalid price (AC3)" do
      post products_path, params: valid_params.deep_merge(product: { starting_price: 0 })

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("ราคาต้องอยู่ระหว่าง 1–20,000 บาท")
    end

    it "attaches uploaded images and a certificate" do
      post products_path, params: valid_params.deep_merge(
        product: { images: [ fixture_upload("image.jpg"), fixture_upload("image.png") ],
                   certificate: fixture_upload("certificate.pdf") }
      )

      product = Product.last
      expect(product.images.count).to eq(2)
      expect(product.certificate).to be_attached
    end
  end

  describe "PATCH /products/:id (#15)" do
    before { sign_in seller }

    it "updates a draft (AC1)" do
      product = create(:product, seller: seller)

      patch product_path(product), params: { product: { title: "ชื่อใหม่" } }

      expect(product.reload.title).to eq("ชื่อใหม่")
    end

    it "updates a rejected product and keeps it rejected (AC2)" do
      product = create(:product, :rejected, seller: seller)

      patch product_path(product), params: { product: { title: "แก้แล้ว" } }

      expect(product.reload).to have_attributes(title: "แก้แล้ว", status: "rejected")
    end

    it "refuses a pending_review product (AC3)" do
      product = create(:product, :pending_review, seller: seller)

      patch product_path(product), params: { product: { title: "แอบแก้" } }

      expect(product.reload.title).not_to eq("แอบแก้")
      expect(flash[:alert]).to eq("สินค้ากำลังรอตรวจ แก้ไขไม่ได้")
    end

    it "refuses an approved product (AC4)" do
      product = create(:product, :approved, seller: seller)

      patch product_path(product), params: { product: { title: "แอบแก้" } }

      expect(product.reload.title).not_to eq("แอบแก้")
      expect(flash[:alert]).to eq("สินค้าที่อนุมัติแล้วแก้ไขไม่ได้")
    end

    it "returns 404 for another user's product (AC5)" do
      product = create(:product, seller: other)

      patch product_path(product), params: { product: { title: "แอบแก้" } }

      expect(response).to have_http_status(:not_found)
      expect(product.reload.title).not_to eq("แอบแก้")
    end

    it "keeps existing images and adds new ones (#10 AC3)" do
      product = create(:product, seller: seller)
      product.images.attach(Array.new(11) { image_blob })
      kept = product.images.map(&:signed_id)

      patch product_path(product), params: { product: { images: kept + [ fixture_upload("image.png") ] } }

      expect(product.reload.images.count).to eq(12)
    end

    it "refuses a 13th image and keeps the existing 12 (#10 AC4)" do
      product = create(:product, seller: seller)
      product.images.attach(Array.new(12) { image_blob })
      kept = product.images.map(&:signed_id)

      patch product_path(product), params: { product: { images: kept + [ fixture_upload("image.png") ] } }

      expect(response.body).to include("อัปโหลดได้สูงสุด 12 รูป")
      expect(product.reload.images.count).to eq(12)
    end
  end

  describe "DELETE /products/:id (#15 AC6)" do
    before { sign_in seller }

    it "deletes a draft" do
      product = create(:product, seller: seller)

      expect { delete product_path(product) }.to change(Product, :count).by(-1)
    end

    it "does not delete a non-draft product" do
      product = create(:product, :rejected, seller: seller)

      expect { delete product_path(product) }.not_to change(Product, :count)
    end
  end
end
