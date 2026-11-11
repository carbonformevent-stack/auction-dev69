require "rails_helper"

RSpec.describe "Admin review page" do
  let(:admin) { create(:user, :admin, name: "สมชาย แอดมิน") }
  let(:seller) { create(:user, name: "อรุณี สุขใจ") }

  before { sign_in admin }

  describe "header" do
    it "shows the position in the queue while the product is pending" do
      create(:product, :pending_review, submitted_at: 3.hours.ago)
      product = create(:product, :pending_review, submitted_at: 2.hours.ago)
      create(:product, :pending_review, submitted_at: 1.hour.ago)

      get admin_product_path(product)

      expect(response.body).to include("← คิวรอตรวจสอบ (2 จาก 3)")
    end

    it "shows a plain back link once the product is decided" do
      get admin_product_path(create(:product, :approved))

      expect(response.body).to include("← คิวรอตรวจสอบ")
      expect(response.body).not_to match(/คิวรอตรวจสอบ \(\d+ จาก/)
    end

    it "shows the category, resubmission round and send time" do
      product = create(:product, :pending_review, category: :painting, submitted_at: Time.zone.local(2026, 11, 10, 22, 20))
      create(:product_review, :rejected, product: product, created_at: Time.zone.local(2026, 11, 9, 10, 15))

      get admin_product_path(product)

      expect(response.body).to include("ภาพวาด · ส่งใหม่ครั้งที่ 2 · 10 พ.ย. 22:20")
    end
  end

  describe "result banners" do
    it "shows an approved product as ready for an auction without promising an email" do
      get admin_product_path(create(:product, :approved))

      expect(response.body).to include("อนุมัติแล้ว", "สินค้าพร้อมนำไปจัดประมูล")
      expect(response.body).not_to include("อีเมล")
    end

    it "shows the reason of a rejected product" do
      product = create(:product, :rejected)
      create(:product_review, :rejected, product: product, reason: "ใบรับรองไม่ตรงกับสินค้า")

      get admin_product_path(product)

      expect(response.body).to include("ไม่อนุมัติแล้ว", "“ใบรับรองไม่ตรงกับสินค้า”")
    end

    it "shows no result banner for a pending product" do
      get admin_product_path(create(:product, :pending_review))

      expect(response.body).not_to include("ไม่อนุมัติแล้ว")
    end
  end

  describe "gallery and certificate" do
    it "offers a full size link and a counter on the gallery" do
      product = create(:product, :pending_review)
      product.images.attach(image_blob)

      get admin_product_path(product)

      expect(response.body).to include("ดูขนาดเต็ม", "1 / 2")
    end

    it "previews the certificate inline with its file name and size" do
      product = create(:product, :pending_review)
      product.certificate.attach(fixture_upload("certificate.pdf"))

      get admin_product_path(product)

      expect(response.body).to include("PDF", "certificate.pdf", "เปิดในแท็บใหม่", "<iframe", "disposition=inline")
    end

    it "omits the certificate panel when there is no certificate" do
      get admin_product_path(create(:product, :pending_review))

      expect(response.body).not_to include("<iframe")
    end
  end

  describe "seller card" do
    it "shows the seller, membership month in Buddhist era and how their listings fared" do
      seller.update_columns(created_at: Time.zone.local(2026, 10, 3))
      product = create(:product, :pending_review, seller: seller)
      create(:product_review, product: create(:product, :approved, seller: seller))
      create(:product_review, :rejected, product: create(:product, :rejected, seller: seller))

      get admin_product_path(product)

      expect(response.body).to include("อรุณี สุขใจ", "สมาชิกตั้งแต่ ต.ค. 2569")
      expect(response.body).to include('data-seller-stat="listed" data-value="3"')
    end

    it "does not claim the email is verified" do
      get admin_product_path(create(:product, :pending_review))

      expect(response.body).not_to include("ยืนยันอีเมลแล้ว")
    end
  end

  describe "status history" do
    it "shows who decided and why" do
      product = create(:product, :rejected)
      create(:product_review, :rejected, product: product, reviewer: admin, reason: "ขอรูปด้านหลังกรอบภาพเพิ่ม")

      get admin_product_path(product)

      expect(response.body).to include("ประวัติสถานะ", "สมชาย แอดมิน", "ขอรูปด้านหลังกรอบภาพเพิ่ม")
    end
  end

  describe "decision bar" do
    it "is shown for a pending product with the hint and both buttons" do
      product = create(:product, :pending_review)

      get admin_product_path(product)

      expect(response.body).to include("ตรวจครบทุกรูปและใบรับรองแล้วจึงตัดสินใจ", admin_product_approval_path(product), "ไม่อนุมัติ")
    end

    it "approves without a browser confirmation" do
      get admin_product_path(create(:product, :pending_review))

      expect(response.body).not_to include("อนุมัติสินค้านี้?")
    end

    %i[approved rejected].each do |status|
      it "is not shown for a #{status} product" do
        get admin_product_path(create(:product, status))

        expect(response.body).not_to include("ตรวจครบทุกรูปและใบรับรองแล้วจึงตัดสินใจ")
      end
    end
  end

  describe "reject dialog" do
    before { get admin_product_path(create(:product, :pending_review)) }

    it "explains the consequence for the seller" do
      expect(response.body).to include("ไม่อนุมัติสินค้านี้", "ผู้ขายจะเห็นเหตุผลนี้และแก้ไขแล้วส่งใหม่ได้", 'aria-modal="true"')
    end

    it "offers the four common reasons as shortcuts" do
      expect(response.body).to include("รูปไม่ชัด", "ข้อมูลไม่ครบ", "ใบรับรองไม่ตรงกับสินค้า", "ราคาไม่สอดคล้องกับสภาพ")
    end

    it "requires at least ten characters in the field and says so" do
      expect(response.body).to include('minlength="10"', "อย่างน้อย 10 ตัวอักษร", 'name="rejection[reason]"')
    end

    it "disables the confirm button until the reason is long enough" do
      button = Nokogiri::HTML(response.body).at_css("button[data-reject-dialog-target='submit']")

      expect(button.text.strip).to eq("ยืนยันไม่อนุมัติ")
      expect(button.key?("disabled")).to be(true)
    end

    it "is wired to the reject-dialog controller" do
      expect(response.body).to include('data-controller="reject-dialog"')
    end
  end
end
