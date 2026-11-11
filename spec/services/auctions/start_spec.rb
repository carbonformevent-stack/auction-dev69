require "rails_helper"

RSpec.describe Auctions::Start do
  let(:auction) { create(:auction) }

  it "moves scheduled → running once starts_at is reached" do
    travel_to(auction.starts_at) do
      expect(described_class.call(auction: auction)).to be(true)
    end

    expect(auction.reload).to be_running
  end

  it "does nothing before starts_at" do
    expect(described_class.call(auction: auction)).to be(false)
    expect(auction.reload).to be_scheduled
  end

  it "does nothing to a cancelled auction" do
    Auctions::Cancel.call(auction: auction)

    travel_to(auction.starts_at + 1.minute) do
      expect(described_class.call(auction: auction)).to be(false)
    end
    expect(auction.reload).to be_cancelled
  end

  it "does nothing when another process already started it" do
    stale = Auction.find(auction.id)
    travel_to(auction.starts_at) do
      described_class.call(auction: auction)

      expect(described_class.call(auction: stale)).to be(false)
    end
    expect(auction.reload).to be_running
  end
end
