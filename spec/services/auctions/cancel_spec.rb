require "rails_helper"

RSpec.describe Auctions::Cancel do
  it "cancels a scheduled auction and frees the product for a new auction" do
    auction = create(:auction)

    described_class.call(auction: auction)

    expect(auction.reload).to be_cancelled
    expect(Product.ready_for_auction).to include(auction.product)
  end

  it "refuses auctions that already started or ended (cancel only before start)" do
    %i[running closed settled cancelled].each do |status|
      auction = create(:auction, :running, status: status)

      expect { described_class.call(auction: auction) }.to raise_error(Auction::InvalidTransition)
      expect(auction.reload.status).to eq(status.to_s)
    end
  end
end
