require "rails_helper"

RSpec.describe Auctions::StartJob do
  include ActiveJob::TestHelper

  it "opens the auction when it runs at starts_at" do
    auction = create(:auction)

    travel_to(auction.starts_at) { described_class.perform_now(auction) }

    expect(auction.reload).to be_running
  end

  it "runs end-to-end: created → job fires at starts_at → running" do
    product = create(:product, :approved)
    starts_at = 1.day.from_now.change(min: 0)
    auction = Auctions::Create.call(product: product, admin: create(:user, :admin), auction_type: "fpsba",
                                    starts_at: starts_at, ends_at: starts_at + 1.hour)

    travel_to(starts_at) { perform_enqueued_jobs }

    expect(auction.reload).to be_running
  end

  it "re-schedules itself when the queue wakes it slightly before starts_at" do
    auction = create(:auction)

    travel_to(auction.starts_at - 0.05.seconds) do
      expect { described_class.perform_now(auction) }
        .to have_enqueued_job(described_class).with(auction).at(auction.starts_at)
    end
    expect(auction.reload).to be_scheduled
  end

  it "does not re-schedule a cancelled auction" do
    auction = create(:auction)
    Auctions::Cancel.call(auction: auction)

    expect { described_class.perform_now(auction) }.not_to have_enqueued_job(described_class)
  end

  it "is discarded when the auction no longer exists" do
    auction = create(:auction)
    described_class.perform_later(auction)
    auction.destroy

    expect { perform_enqueued_jobs }.not_to raise_error
  end
end
