require "rails_helper"

RSpec.describe Auctions::Create do
  include ActiveJob::TestHelper

  let(:admin) { create(:user, :admin) }
  let(:product) { create(:product, :approved, starting_price: 12_000) }
  let(:starts_at) { 2.days.from_now.change(hour: 20, min: 0) }

  def create_auction(for_product: product, start: starts_at, ends: start + 3.days)
    described_class.call(product: for_product, admin: admin, auction_type: "fpsba", starts_at: start, ends_at: ends)
  end

  it "creates a scheduled FPSBA auction, copying the starting price and recording the admin" do
    auction = create_auction

    expect(auction).to be_persisted
    expect(auction).to have_attributes(status: "scheduled", auction_type: "fpsba", starting_price: 12_000,
                                       created_by: admin, starts_at: starts_at, ends_at: starts_at + 3.days, settings: {})
  end

  it "keeps the starting price when the product price changes later (snapshot)" do
    auction = create_auction
    product.update_column(:starting_price, 15_000)

    expect(auction.reload.starting_price).to eq(12_000)
  end

  it "schedules StartJob at starts_at" do
    auction = nil

    expect { auction = create_auction }.to have_enqueued_job(Auctions::StartJob).at(starts_at)
    expect(enqueued_jobs.last[:args].first).to eq("_aj_globalid" => auction.to_global_id.to_s)
  end

  it "refuses products that are not approved" do
    %i[product pending_review rejected].each do |trait|
      not_approved = trait == :product ? create(:product) : create(:product, trait)

      auction = create_auction(for_product: not_approved)

      expect(auction).not_to be_persisted
      expect(auction.errors[:base]).to include("สร้างการประมูลได้เฉพาะสินค้าที่อนุมัติแล้ว")
    end
  end

  it "refuses a second active auction for the same product" do
    create_auction

    second = create_auction

    expect(second).not_to be_persisted
    expect(second.errors[:base]).to include("สินค้านี้มีรอบประมูลที่ยังไม่จบอยู่แล้ว")
    expect(product.auctions.count).to eq(1)
  end

  it "turns the unique-index race (two admins at once) into a validation error" do
    create(:auction, product: product)
    allow(product.auctions).to receive(:active).and_return(Auction.none)

    second = create_auction

    expect(second).not_to be_persisted
    expect(second.errors[:base]).to include("สินค้านี้มีรอบประมูลที่ยังไม่จบอยู่แล้ว")
  end

  it "returns validation errors for a past start or a duration outside 1 hour – 7 days" do
    expect(create_auction(start: 1.minute.ago, ends: 1.hour.from_now).errors[:starts_at]).to be_present
    expect(create_auction(ends: starts_at + 30.minutes).errors[:ends_at]).to be_present
    expect(Auction.count).to eq(0)
  end

  it "does not schedule a job when the auction is invalid" do
    product # สร้างสินค้า (และ job วิเคราะห์รูปของ Active Storage) ก่อนนับ job

    expect { create_auction(start: 1.minute.ago, ends: 1.hour.from_now) }.not_to have_enqueued_job(Auctions::StartJob)
  end
end
