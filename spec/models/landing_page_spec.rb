require "rails_helper"

RSpec.describe LandingPage do
  subject(:landing) { described_class.new(now: now) }

  let(:now) { Time.zone.local(2026, 11, 11, 10, 0, 0) }

  it "lists one card per product category" do
    expect(landing.categories.map(&:key)).to match_array(Product.categories.keys)
  end

  it "keeps sample starting prices within the allowed product price range" do
    prices = (landing.live_auctions + landing.upcoming_auctions).map(&:starting_price)

    expect(prices).to all(be_between(Product::PRICE_RANGE.min, Product::PRICE_RANGE.max))
  end

  it "has live auctions running now and upcoming auctions starting later" do
    expect(landing.live_auctions).to all(be_live(now))
    expect(landing.upcoming_auctions.map(&:starts_at)).to all(be > now)
  end

  it "features a live auction and pairs an upcoming and a live one beside it" do
    upcoming, live = landing.hero_side_auctions

    expect(landing.featured_auction).to be_live(now)
    expect(upcoming).not_to be_live(now)
    expect(live).to be_live(now)
  end

  it "flags only auctions with less than an hour left as closing soon" do
    expect(landing.live_auctions.select { |auction| auction.closing_soon?(now) }.map(&:title))
      .to eq([ "กำไลข้อมือนาก ลายดอกพิกุล" ])
  end
end
