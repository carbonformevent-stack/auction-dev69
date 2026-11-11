require "rails_helper"

RSpec.describe Admin::SellerStats do
  subject(:stats) { described_class.new(seller) }

  let(:seller) { create(:user) }


  it "counts every product the seller listed, drafts included" do
    create(:product, seller: seller)
    create(:product, :approved, seller: seller)
    create(:product)

    expect(stats.listed).to eq(2)
  end

  it "counts approvals and rejections across all rounds" do
    approved = create(:product, :approved, seller: seller)
    rejected = create(:product, :pending_review, seller: seller)
    create(:product_review, product: approved)
    create(:product_review, :rejected, product: rejected, created_at: 2.days.ago)
    create(:product_review, :rejected, product: rejected, created_at: 1.day.ago)

    expect([ stats.approved, stats.rejected ]).to eq([ 1, 2 ])
  end

  it "ignores other sellers' reviews" do
    create(:product_review, :rejected)

    expect([ stats.approved, stats.rejected ]).to eq([ 0, 0 ])
  end

  it "is all zero for a seller without products" do
    expect([ stats.listed, stats.approved, stats.rejected ]).to eq([ 0, 0, 0 ])
  end
end
