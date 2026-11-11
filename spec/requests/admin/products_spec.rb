require "rails_helper"

RSpec.describe "Admin::Products" do
  let(:admin) { create(:user, :admin) }

  describe "GET /admin/products (#16)" do
    it "redirects guests to sign in" do
      get admin_products_path

      expect(response).to redirect_to(new_user_session_path)
    end

    it "forbids normal users (AC3)" do
      sign_in create(:user)

      get admin_products_path

      expect(response).to have_http_status(:forbidden)
    end

    it "lists only pending products, oldest first, with summary data (AC1, AC2)" do
      seller = create(:user, name: "ผู้ขายหนึ่ง")
      newer = create(:product, :pending_review, title: "ส่งทีหลัง", submitted_at: 1.minute.ago)
      older = create(:product, :pending_review, title: "ส่งก่อน", seller: seller, starting_price: 4500,
                                                category: :painting, submitted_at: 1.hour.ago)
      create(:product, title: "ยังเป็นร่าง")
      sign_in admin

      get admin_products_path

      body = response.body
      expect(body.index(older.title)).to be < body.index(newer.title)
      expect(body).not_to include("ยังเป็นร่าง")
      expect(body).to include("ผู้ขายหนึ่ง", "฿4,500", "ภาพวาด", "<img")
    end

    it "shows an empty message (AC4)" do
      sign_in admin

      get admin_products_path

      expect(response.body).to include("ไม่มีสินค้ารอตรวจ")
    end
  end

  describe "GET /admin/products queue overview" do
    let(:now) { Time.zone.local(2026, 11, 11, 12, 0) }

    before do
      travel_to(now)
      sign_in admin
    end

    def stat(name) = response.body[/data-stat="#{name}" data-value="(\d+)"/, 1].to_i

    it "summarises the queue in four stat cards" do
      create(:product, :pending_review, submitted_at: now - 3.hours)
      create(:product, :pending_review, submitted_at: now - 49.hours)
      resubmitted = create(:product, :pending_review, submitted_at: now - 1.hour)
      create(:product_review, :rejected, product: resubmitted, created_at: now - 1.day)
      create(:product_review, product: create(:product, :approved), created_at: now - 2.hours)

      get admin_products_path

      expect([ stat("pending"), stat("overdue"), stat("resubmitted"), stat("reviewed_today") ]).to eq([ 3, 1, 1, 1 ])
    end

    it "labels the stat cards as in the design" do
      get admin_products_path

      expect(response.body).to include("รอตรวจสอบ", "รอเกิน 48 ชั่วโมง", "ส่งใหม่หลังแก้ไข", "ตรวจแล้ววันนี้")
    end

    it "uses the new subtitle" do
      get admin_products_path

      expect(response.body).to include("เรียงจากส่งก่อน ตรวจรายการที่รอนานที่สุดก่อน")
    end

    it "shows category chips with counts and marks all as current by default" do
      create(:product, :pending_review, category: :watch)
      create_list(:product, 2, :pending_review, category: :painting)

      get admin_products_path

      expect(response.body.scan(/data-category-chip="(\w+)" data-count="(\d+)"/))
        .to eq([ %w[all 3], %w[watch 1], %w[jewelry 0], %w[old_book 0], %w[painting 2] ])
    end

    it "filters by category" do
      create(:product, :pending_review, category: :watch, title: "นาฬิกาในคิว")
      create(:product, :pending_review, category: :painting, title: "ภาพวาดในคิว")

      get admin_products_path(category: "painting")

      expect(response.body).to include("ภาพวาดในคิว")
      expect(response.body).not_to include("นาฬิกาในคิว")
    end

    it "ignores an unknown or malformed category" do
      create(:product, :pending_review, title: "ยังอยู่ในคิว")

      get admin_products_path, params: { category: { "x" => "y" } }

      expect(response.body).to include("ยังอยู่ในคิว")
    end

    it "explains an empty filter while keeping the chips" do
      create(:product, :pending_review, category: :watch)

      get admin_products_path(category: "painting")

      expect(response.body).to include("ไม่มีสินค้าประเภทนี้ในคิว", 'aria-label="กรองตามประเภท"')
    end

    it "shows the table columns" do
      create(:product, :pending_review)

      get admin_products_path

      expect(response.body).to include("<th", "สินค้า", "ผู้ขาย", "ราคาเริ่มต้น", "ใบรับรอง", "ส่งเมื่อ", "การทำงาน")
    end

    it "shows image count, certificate and the review link on each row" do
      product = create(:product, :pending_review)
      product.certificate.attach(fixture_upload("certificate.pdf"))

      get admin_products_path

      expect(response.body).to include("1 รูป", "มี PDF", admin_product_path(product))
    end

    it "shows a dash when there is no certificate" do
      create(:product, :pending_review)

      get admin_products_path

      expect(response.body).to include(">—<")
    end

    it "marks resubmissions with their round" do
      product = create(:product, :pending_review)
      create(:product_review, :rejected, product: product)

      get admin_products_path

      expect(response.body).to include("ส่งใหม่ครั้งที่ 2")
    end

    it "does not mark a first submission as a resubmission" do
      create(:product, :pending_review)

      get admin_products_path

      expect(response.body).not_to include("ส่งใหม่ครั้งที่")
    end

    it "shows when it was sent and how long it has been waiting" do
      create(:product, :pending_review, submitted_at: now - 65.hours)

      get admin_products_path

      expect(response.body).to include("8 พ.ย. 19:00", "รอ 2 วัน 17 ชม.")
    end

    it "flags only the rows that waited more than 48 hours" do
      create(:product, :pending_review, submitted_at: now - 48.hours)
      create(:product, :pending_review, submitted_at: now - 48.hours - 1.minute)

      get admin_products_path

      expect(response.body.scan('data-overdue="true"').size).to eq(1)
    end

    it "loads reviews with a single query however long the queue is" do
      create_list(:product, 3, :pending_review)
      queries = []
      # preload ใช้ product_id IN (...) ส่วน N+1 จะเป็น product_id = ? ต่อสินค้า — นับทั้งสองแบบ
      per_product = /"product_reviews"\."product_id" (=|IN)/
      counter = ->(*, payload) { queries << payload[:sql] if payload[:sql].match?(per_product) }

      ActiveSupport::Notifications.subscribed(counter, "sql.active_record") { get admin_products_path }

      expect(queries.size).to be <= 1
    end
  end

  describe "GET /admin/products/:id (#17 AC2, #12 AC5, #19)" do
    it "shows every field, images, certificate, proposed duration and history with reviewers" do
      product = create(:product, :pending_review, desired_duration_minutes: 4320, description: "ล้างเครื่องแล้ว")
      product.certificate.attach(fixture_upload("certificate.pdf"))
      create(:product_review, :rejected, product: product, reviewer: create(:user, :admin, name: "สมชาย"),
                                         reason: "ขอรูปเพิ่ม")
      sign_in admin

      get admin_product_path(product)

      expect(response.body).to include(product.title, "ล้างเครื่องแล้ว", "3 วัน", "certificate.pdf",
                                       "<img", "สมชาย", "ขอรูปเพิ่ม", "อนุมัติ")
    end

    it "forbids normal users" do
      sign_in create(:user)

      get admin_product_path(create(:product, :pending_review))

      expect(response).to have_http_status(:forbidden)
    end
  end
end
