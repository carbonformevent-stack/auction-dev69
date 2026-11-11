require "rails_helper"

RSpec.describe Auctions::StartDueJob do
  it "starts every scheduled auction whose starts_at has passed, and leaves the rest" do
    due = create(:auction, starts_at: 1.hour.from_now, ends_at: 2.days.from_now)
    later = create(:auction, starts_at: 3.hours.from_now, ends_at: 2.days.from_now)
    cancelled = create(:auction, :cancelled, starts_at: 1.hour.from_now, ends_at: 2.days.from_now)

    travel(2.hours) { described_class.perform_now }

    expect(due.reload).to be_running
    expect(later.reload).to be_scheduled
    expect(cancelled.reload).to be_cancelled
  end
end
