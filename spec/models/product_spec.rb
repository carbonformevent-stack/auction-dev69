require "rails_helper"

RSpec.describe Product do
  subject(:product) { build(:product) }

  def errors_on(attribute)
    product.validate
    product.errors[attribute]
  end

  describe "associations" do
    it { is_expected.to belong_to(:seller).class_name("User") }
    it { is_expected.to have_many(:reviews).class_name("ProductReview") }
  end

  it "is valid with the factory defaults and starts as draft" do
    expect(product).to be_valid
    expect(product).to be_draft
  end

  describe "category (#9 AC2)" do
    it "rejects a missing category" do
      product.category = nil

      expect(errors_on(:category)).to include("กรุณาเลือกประเภทสินค้า")
    end

    it "rejects a value outside the four categories" do
      product.category = "car"

      expect(errors_on(:category)).to include("ประเภทสินค้าไม่ถูกต้อง")
    end

    it "accepts all four categories" do
      %w[watch jewelry old_book painting].each do |category|
        product.category = category
        expect(product).to be_valid
      end
    end
  end

  describe "starting_price (#9 AC3–AC7)" do
    let(:price_error) { "ราคาต้องอยู่ระหว่าง 1–20,000 บาท" }

    it("rejects 0") { product.starting_price = 0; expect(errors_on(:starting_price)).to include(price_error) }
    it("accepts 1") { product.starting_price = 1; expect(product).to be_valid }
    it("accepts 20,000") { product.starting_price = 20_000; expect(product).to be_valid }
    it("rejects 20,001") { product.starting_price = 20_001; expect(errors_on(:starting_price)).to include(price_error) }
    it("rejects a decimal") { product.starting_price = "100.50"; expect(errors_on(:starting_price)).to be_present }
    it("rejects blank") { product.starting_price = ""; expect(errors_on(:starting_price)).to be_present }

    it "is enforced by a database check constraint" do
      product.save!

      expect { product.update_column(:starting_price, 20_001) }.to raise_error(ActiveRecord::StatementInvalid)
    end
  end

  describe "title (#9 AC8)" do
    it("rejects blank") { product.title = ""; expect(errors_on(:title)).to include("กรุณากรอกชื่อสินค้า") }
    it("accepts 150 Thai characters") { product.title = "ก" * 150; expect(product).to be_valid }
    it("rejects 151 characters") { product.title = "ก" * 151; expect(errors_on(:title)).to be_present }
  end

  describe "description (#9 AC9)" do
    it("rejects blank") { product.description = ""; expect(errors_on(:description)).to be_present }
    it("accepts 5,000 characters") { product.description = "ก" * 5000; expect(product).to be_valid }
    it("rejects 5,001 characters") { product.description = "ก" * 5001; expect(errors_on(:description)).to be_present }
  end

  describe "desired_duration_minutes (#12)" do
    let(:duration_error) { "ระยะเวลาต้องอยู่ระหว่าง 1 ชั่วโมง – 7 วัน" }

    it("rejects 59 minutes") { product.desired_duration_minutes = 59; expect(errors_on(:desired_duration_minutes)).to include(duration_error) }
    it("accepts 1 hour") { product.desired_duration_minutes = 60; expect(product).to be_valid }
    it("accepts 7 days") { product.desired_duration_minutes = 10_080; expect(product).to be_valid }
    it("rejects 7 days 1 hour") { product.desired_duration_minutes = 10_140; expect(errors_on(:desired_duration_minutes)).to include(duration_error) }

    it "offers 5 days as a duration choice and accepts it" do
      product.desired_duration_minutes = 7200

      expect(Product::DURATION_CHOICES).to include(7200)
      expect(product).to be_valid
    end

    it "keeps the duration choices sorted ascending" do
      expect(Product::DURATION_CHOICES).to eq(Product::DURATION_CHOICES.sort)
    end

    it "is enforced by a database check constraint" do
      product.save!

      expect { product.update_column(:desired_duration_minutes, 59) }.to raise_error(ActiveRecord::StatementInvalid)
    end
  end

  describe "images (#10)" do
    it "allows saving a draft without images (AC1)" do
      expect(product).to be_valid
    end

    it "requires at least one image when submitting (AC1)" do
      product.validate(:submit)

      expect(product.errors[:images]).to include("ต้องมีรูปอย่างน้อย 1 รูป")
    end

    it "accepts one 2MB jpg and is submittable (AC2)" do
      product.images.attach(sized_upload(2.megabytes, content_type: "image/jpeg", filename: "watch.jpg"))

      expect(product.valid?(:submit)).to be(true)
    end

    it "accepts 12 images (AC3)" do
      product.images.attach(Array.new(12) { image_blob })

      expect(product).to be_valid
    end

    it "rejects 13 images (AC4)" do
      product.images.attach(Array.new(13) { image_blob })

      expect(errors_on(:images)).to include("อัปโหลดได้สูงสุด 12 รูป")
    end

    it "accepts jpg, png and webp (AC5)" do
      product.images.attach(%w[image.jpg image.png image.webp].map { fixture_upload(_1) })

      expect(product).to be_valid
    end

    it "rejects gif, pdf and a gif renamed to .jpg by real content type (AC5)" do
      product.images.attach([ fixture_upload("image.gif"), fixture_upload("certificate.pdf"),
                              fixture_upload("gif-renamed.jpg", "image/jpeg") ])

      expect(errors_on(:images)).to contain_exactly(
        "image.gif: รับเฉพาะไฟล์ JPG, PNG หรือ WebP",
        "certificate.pdf: รับเฉพาะไฟล์ JPG, PNG หรือ WebP",
        "gif-renamed.jpg: รับเฉพาะไฟล์ JPG, PNG หรือ WebP"
      )
    end

    it "accepts exactly 5MB (AC6)" do
      product.images.attach(sized_upload(5.megabytes, content_type: "image/jpeg", filename: "ok.jpg"))

      expect(product).to be_valid
    end

    it "rejects 5MB + 1 byte and names the file (AC6)" do
      product.images.attach(sized_upload(5.megabytes + 1, content_type: "image/jpeg", filename: "big.jpg"))

      expect(errors_on(:images)).to include("big.jpg: ไฟล์ใหญ่เกิน 5MB")
    end
  end

  describe "certificate (#11)" do
    it "is optional (AC1)" do
      expect(product).to be_valid
    end

    it "accepts a PDF of exactly 10MB (AC2)" do
      product.certificate.attach(sized_upload(10.megabytes, content_type: "application/pdf", filename: "cert.pdf"))

      expect(product).to be_valid
    end

    it "rejects a PDF over 10MB (AC3)" do
      product.certificate.attach(sized_upload(10.megabytes + 1, content_type: "application/pdf", filename: "cert.pdf"))

      expect(errors_on(:certificate)).to include("ใบรับรองต้องไม่เกิน 10MB")
    end

    it "rejects docx, jpg and a docx renamed to .pdf (AC4)" do
      [ fixture_upload("document.docx"), fixture_upload("image.jpg"),
        fixture_upload("docx-renamed.pdf", "application/pdf") ].each do |upload|
        product.certificate.attach(upload)
        expect(errors_on(:certificate)).to include("ใบรับรองต้องเป็นไฟล์ PDF")
      end
    end

    it "keeps only the newest file (AC5)" do
      product.certificate.attach(fixture_upload("certificate.pdf"))
      product.save!
      product.update!(certificate: sized_upload(1.kilobyte, content_type: "application/pdf", filename: "new.pdf"))

      expect(product.reload.certificate.filename.to_s).to eq("new.pdf")
      expect(ActiveStorage::Attachment.where(record: product, name: "certificate").count).to eq(1)
    end
  end

  describe "edit rules (#15)" do
    let(:seller) { create(:user) }
    let(:other) { create(:user) }

    it "lets the seller edit draft and rejected products" do
      expect(build(:product, seller: seller)).to be_editable_by(seller)
      expect(build(:product, :rejected, seller: seller)).to be_editable_by(seller)
    end

    it "blocks editing pending_review products with a reason" do
      pending = build(:product, :pending_review, seller: seller)

      expect(pending).not_to be_editable_by(seller)
      expect(pending.edit_blocked_reason).to eq("สินค้ากำลังรอตรวจ แก้ไขไม่ได้")
    end

    it "blocks editing approved products with a reason" do
      approved = build(:product, :approved, seller: seller)

      expect(approved).not_to be_editable_by(seller)
      expect(approved.edit_blocked_reason).to eq("สินค้าที่อนุมัติแล้วแก้ไขไม่ได้")
    end

    it "never lets another user edit" do
      expect(build(:product, seller: seller)).not_to be_editable_by(other)
    end

    it "allows deleting drafts only" do
      expect(build(:product, seller: seller)).to be_destroyable_by(seller)
      expect(build(:product, :rejected, seller: seller)).not_to be_destroyable_by(seller)
    end
  end

  describe ".review_queue" do
    it "lists only pending_review products, oldest submission first" do
      newer = create(:product, :pending_review, submitted_at: 1.minute.ago)
      older = create(:product, :pending_review, submitted_at: 1.hour.ago)
      create(:product)
      create(:product, :approved)

      expect(described_class.review_queue).to eq([ older, newer ])
    end
  end

  describe "#transition!" do
    it "changes status when the current status matches" do
      product = create(:product, :pending_review)

      product.transition!(from: :pending_review, to: :approved)

      expect(product).to be_approved
    end

    it "raises when another request already changed the status" do
      product = create(:product, :pending_review)
      stale_copy = described_class.find(product.id)
      product.transition!(from: :pending_review, to: :approved)

      expect { stale_copy.transition!(from: :pending_review, to: :rejected) }
        .to raise_error(Product::InvalidTransition)
      expect(product.reload).to be_approved
    end
  end

  describe "#latest_rejection" do
    it "returns the most recent rejected review" do
      product = create(:product, :rejected)
      create(:product_review, :rejected, product: product, reason: "เก่า", created_at: 2.days.ago)
      create(:product_review, :rejected, product: product, reason: "ล่าสุด", created_at: 1.day.ago)

      expect(product.reload.latest_rejection.reason).to eq("ล่าสุด")
    end
  end
end
