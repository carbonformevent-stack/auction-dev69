require "rails_helper"

RSpec.describe LandingHelper do
  let(:now) { Time.zone.local(2026, 11, 11, 10, 0, 0) }

  describe "#time_left_label" do
    {
      45.minutes => "45 นาที",
      30.seconds => "1 นาที",
      6.hours => "6 ชม.",
      1.day + 4.hours + 12.minutes + 36.seconds => "1 วัน 04:12",
      2.days => "2 วัน",
      -5.minutes => "1 นาที"
    }.each do |left, label|
      it "shows #{left.inspect} as #{label}" do
        expect(helper.time_left_label(now + left, now: now)).to eq(label)
      end
    end
  end

  describe "#countdown_text" do
    it "includes days only when at least a day is left" do
      expect(helper.countdown_text(now + 1.day + 4.hours + 12.minutes + 36.seconds, now: now)).to eq("1 วัน 04:12:36")
      expect(helper.countdown_text(now + 59.minutes + 5.seconds, now: now)).to eq("00:59:05")
    end

    it "stops at zero after the end" do
      expect(helper.countdown_text(now - 1.minute, now: now)).to eq("00:00:00")
    end
  end

  describe "#thai_weekday_time" do
    it "formats with a Thai weekday and month" do
      expect(helper.thai_weekday_time(Time.zone.local(2026, 11, 14, 20, 0))).to eq("ส. 14 พ.ย. 20:00")
    end
  end

  describe "#auction_badge" do
    let(:landing) { LandingPage.new(now: now) }

    it "highlights auctions closing within an hour" do
      closing = landing.live_auctions.find { |auction| auction.closing_soon?(now) }

      expect(helper.auction_badge(closing, now: now)).to include("ปิดใน 45 นาที", "bg-accent")
    end

    it "shows the start time for upcoming auctions" do
      expect(helper.auction_badge(landing.upcoming_auctions.first, now: now)).to include("เริ่ม ")
    end
  end
end
