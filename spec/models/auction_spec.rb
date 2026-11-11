require "rails_helper"

RSpec.describe Auction do
  describe "validations" do
    it "is valid with a future start and a duration of 1 hour to 7 days" do
      expect(build(:auction)).to be_valid
    end

    it "rejects a start time that is not in the future (on create)" do
      auction = build(:auction, starts_at: 1.minute.ago, ends_at: 1.hour.from_now)

      expect(auction).not_to be_valid
      expect(auction.errors[:starts_at]).to include("เวลาเริ่มต้องอยู่หลังเวลาปัจจุบัน")
    end

    it "accepts exactly 1 hour and exactly 7 days" do
      start = 1.day.from_now

      expect(build(:auction, starts_at: start, ends_at: start + 1.hour)).to be_valid
      expect(build(:auction, starts_at: start, ends_at: start + 7.days)).to be_valid
    end

    it "rejects durations just outside 1 hour – 7 days" do
      start = 1.day.from_now
      errors = [ 59.minutes, 7.days + 1.minute ].map do |duration|
        build(:auction, starts_at: start, ends_at: start + duration).tap(&:validate).errors[:ends_at]
      end

      expect(errors).to all(include("ระยะเวลาต้องอยู่ระหว่าง 1 ชั่วโมง – 7 วัน"))
    end

    it "rejects an auction type that is not available yet" do
      auction = build(:auction, auction_type: "english")

      expect(auction).not_to be_valid
      expect(auction.errors[:auction_type]).to include("วิธีประมูลไม่ถูกต้อง")
    end
  end

  describe "database constraints" do
    it "allows only one active auction per product" do
      auction = create(:auction)
      duplicate = build(:auction, product: auction.product)

      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "allows a new auction once the previous one is cancelled" do
      auction = create(:auction, :cancelled)

      expect(create(:auction, product: auction.product)).to be_scheduled
    end

    it "requires ends_at after starts_at" do
      auction = build(:auction)
      auction.ends_at = auction.starts_at

      expect { auction.save!(validate: false) }.to raise_error(ActiveRecord::StatementInvalid, /CHECK constraint/)
    end
  end

  describe "#cancellable?" do
    it "is true only before the auction starts" do
      expect(build(:auction)).to be_cancellable
      expect(build(:auction, status: :running)).not_to be_cancellable
      expect(build(:auction, :cancelled)).not_to be_cancellable
    end
  end
end
