require "rails_helper"

RSpec.describe "Admin auctions (#20)" do
  let(:admin) { create(:user, :admin) }
  let(:product) { create(:product, :approved, starting_price: 12_000, desired_duration_minutes: 4320) }

  def form_params(date:, time: "20:00", duration: 4320, type: "fpsba")
    { auction: { auction_type: type, start_date: date, start_time: time, duration_minutes: duration } }
  end

  describe "GET /admin/auctions" do
    it "lists approved products ready for auction and existing auctions" do
      sign_in admin
      ready = create(:product, :approved, title: "แหวนพลอยไพลิน")
      scheduled = create(:auction, product: create(:product, :approved, title: "นาฬิกาจัดแล้ว"))
      create(:product, :pending_review, title: "ยังรอตรวจ")

      get admin_auctions_path

      body = Nokogiri::HTML(response.body)
      expect(body.css("[data-ready-product]").map { |row| row["data-ready-product"].to_i }).to eq([ ready.id ])
      expect(body.at_css("[data-auction='#{scheduled.id}']").text).to include("นาฬิกาจัดแล้ว", "กำหนดการ")
      expect(response.body).not_to include("ยังรอตรวจ")
    end

    it "forbids normal users" do
      sign_in create(:user)

      get admin_auctions_path

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /admin/products/:id/auctions/new" do
    before { sign_in admin }

    context "with the default form" do
      subject(:html) { Nokogiri::HTML(response.body) }

      before do
        travel_to(Time.zone.local(2026, 11, 11, 9, 30)) { get new_admin_product_auction_path(product) }
      end

      it "offers FPSBA only; other auction types are listed as coming soon" do
        expect(html.at_css("select[name='auction[auction_type]'] option[selected]")["value"]).to eq("fpsba")
        expect(html.css("select[name='auction[auction_type]'] option[disabled]").map { _1["value"] }).to eq(%w[english vickrey dutch])
      end

      it "starts at the next full hour (Bangkok time)" do
        expect(html.at_css("input[name='auction[start_date]']")["value"]).to eq("2026-11-11")
        expect(html.at_css("input[name='auction[start_time]']")["value"]).to eq("10:00")
      end

      it "defaults the duration to what the seller proposed and labels it" do
        expect(html.at_css("input[name='auction[duration_minutes]'][checked]")["value"]).to eq("4320")
        expect(response.body).to include("3 วัน · ผู้ขายเสนอ")
      end

      it "shows the starting price copied from the product as read-only" do
        expect(html.at_css("#auction-starting-price").to_h).to include("value" => "12,000", "readonly" => "readonly")
        expect(response.body).to include("คัดลอกจากสินค้า ณ เวลาสร้าง แก้ไขไม่ได้")
      end
    end

    it "sends products that are not ready back to the auctions page" do
      create(:auction, product: product)

      get new_admin_product_auction_path(product)

      expect(response).to redirect_to(admin_auctions_path)
      expect(flash[:alert]).to eq("สินค้านี้มีรอบประมูลที่ยังไม่จบอยู่แล้ว")
    end
  end

  describe "POST /admin/products/:id/auctions" do
    before { sign_in admin }

    it "creates a scheduled auction from Bangkok date/time and duration, then redirects with a notice" do
      travel_to Time.zone.local(2026, 11, 11, 9, 0) do
        post admin_product_auctions_path(product), params: form_params(date: "2026-11-15", time: "20:00", duration: 4320)
      end

      auction = product.auctions.last
      expect(auction).to have_attributes(status: "scheduled", starting_price: 12_000, created_by: admin,
                                         starts_at: Time.zone.local(2026, 11, 15, 20, 0),
                                         ends_at: Time.zone.local(2026, 11, 18, 20, 0))
      expect(response).to redirect_to(admin_auctions_path)
      expect(flash[:notice]).to eq("สร้างการประมูลแล้ว · สถานะ “กำหนดการ” จะเปิดรับราคาอัตโนมัติ อา. 15 พ.ย. 2569 20:00 น.")
    end

    it "ignores a starting price sent in the form" do
      post admin_product_auctions_path(product),
           params: form_params(date: 2.days.from_now.to_date.iso8601).deep_merge(auction: { starting_price: 1 })

      expect(product.auctions.last.starting_price).to eq(12_000)
    end

    it "re-renders with an error when the start is in the past" do
      travel_to Time.zone.local(2026, 11, 11, 9, 0) do
        post admin_product_auctions_path(product), params: form_params(date: "2026-11-11", time: "08:59")
      end

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("ข้อผิดพลาด: เวลาเริ่มต้องอยู่หลังเวลาปัจจุบัน")
      expect(product.auctions).to be_empty
    end

    it "re-renders with an error for a duration outside 1 hour – 7 days" do
      post admin_product_auctions_path(product), params: form_params(date: 2.days.from_now.to_date.iso8601, duration: 30)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("ข้อผิดพลาด: ระยะเวลาต้องอยู่ระหว่าง 1 ชั่วโมง – 7 วัน")
    end

    it "re-renders with an error for an auction type that is not available yet" do
      post admin_product_auctions_path(product), params: form_params(date: 2.days.from_now.to_date.iso8601, type: "english")

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("ข้อผิดพลาด: วิธีประมูลไม่ถูกต้อง")
    end

    it "forbids normal users" do
      sign_in create(:user)

      post admin_product_auctions_path(product), params: form_params(date: 2.days.from_now.to_date.iso8601)

      expect(response).to have_http_status(:forbidden)
      expect(product.auctions).to be_empty
    end
  end

  describe "POST /admin/auctions/:id/cancellation" do
    it "cancels a scheduled auction" do
      sign_in admin
      auction = create(:auction)

      post admin_auction_cancellation_path(auction)

      expect(auction.reload).to be_cancelled
      expect(response).to redirect_to(admin_auctions_path)
      expect(flash[:notice]).to include("ยกเลิกการประมูล")
    end

    it "tells the admin when the auction already started" do
      sign_in admin
      auction = create(:auction, :running)

      post admin_auction_cancellation_path(auction)

      expect(auction.reload).to be_running
      expect(flash[:alert]).to eq("สถานะการประมูลเปลี่ยนไปแล้ว กรุณาโหลดหน้าใหม่")
    end

    it "forbids normal users" do
      sign_in create(:user)
      auction = create(:auction)

      post admin_auction_cancellation_path(auction)

      expect(response).to have_http_status(:forbidden)
      expect(auction.reload).to be_scheduled
    end
  end
end
