require "rails_helper"

RSpec.describe ProductsHelper do
  describe "#status_badge" do
    {
      "draft" => "ฉบับร่าง",
      "pending_review" => "รอตรวจสอบ",
      "approved" => "อนุมัติแล้ว",
      "rejected" => "ไม่อนุมัติ"
    }.each do |status, label|
      it "labels #{status} as #{label}" do
        expect(helper.status_badge(build(:product, status: status))).to include(label)
      end
    end

    it "hides the icon from assistive technology" do
      expect(helper.status_badge(build(:product, status: :approved))).to include('aria-hidden="true"')
    end

    it "uses the compact size for tables and the large size for page headers" do
      product = build(:product)

      expect(helper.status_badge(product, size: :sm)).to include("text-xs")
      expect(helper.status_badge(product, size: :lg)).to include("text-sm")
    end
  end

  describe "#thai_short_time" do
    it "formats day, abbreviated Thai month and time without the year" do
      expect(helper.thai_short_time(Time.zone.local(2026, 11, 8, 16, 40))).to eq("8 พ.ย. 16:40")
    end

    it "converts to Bangkok time" do
      expect(helper.thai_short_time(Time.utc(2026, 1, 1, 17, 5))).to eq("2 ม.ค. 00:05")
    end

    it "returns a dash for nil" do
      expect(helper.thai_short_time(nil)).to eq("-")
    end
  end

  describe "#thai_date_be" do
    it "uses the Buddhist era year" do
      expect(helper.thai_date_be(Time.zone.local(2026, 11, 9, 10, 15))).to eq("9 พ.ย. 2569 10:15")
    end

    it "returns a dash for nil" do
      expect(helper.thai_date_be(nil)).to eq("-")
    end
  end

  describe "#thai_month_year_be" do
    it "formats abbreviated month and Buddhist era year" do
      expect(helper.thai_month_year_be(Time.zone.local(2026, 10, 3))).to eq("ต.ค. 2569")
    end
  end

  describe "#waiting_time" do
    let(:now) { Time.zone.local(2026, 11, 11, 12, 0) }

    it "shows less than one hour" do
      expect(helper.waiting_time(now - 59.minutes, now: now)).to eq("รอไม่ถึง 1 ชม.")
    end

    it "shows whole hours below 48 hours" do
      expect(helper.waiting_time(now - 3.hours, now: now)).to eq("รอ 3 ชม.")
      expect(helper.waiting_time(now - 47.hours - 59.minutes, now: now)).to eq("รอ 47 ชม.")
    end

    it "switches to days and hours at exactly 48 hours" do
      expect(helper.waiting_time(now - 48.hours, now: now)).to eq("รอ 2 วัน")
    end

    it "shows days with the remaining hours" do
      expect(helper.waiting_time(now - 65.hours, now: now)).to eq("รอ 2 วัน 17 ชม.")
    end

    it "returns a dash for nil" do
      expect(helper.waiting_time(nil, now: now)).to eq("-")
    end
  end
end
