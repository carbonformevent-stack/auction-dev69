require "rails_helper"

RSpec.describe Products::Approve do
  let(:admin) { create(:user, :admin) }

  it "approves and records the reviewer and time (#17 AC1, #19 AC1)" do
    product = create(:product, :pending_review)

    described_class.call(product: product, reviewer: admin)

    expect(product).to be_approved
    expect(product.reviews.last).to have_attributes(reviewer: admin, decision: "approved", reason: nil)
  end

  it "does not change draft, approved or rejected products (#17 AC3)" do
    %i[product approved rejected].each do |trait|
      product = trait == :product ? create(:product) : create(:product, trait)

      expect { described_class.call(product: product, reviewer: admin) }.to raise_error(Product::InvalidTransition)
      expect(product.reviews.count).to eq(0)
    end
  end

  it "lets only the first of two simultaneous decisions win (#17 AC4)" do
    product = create(:product, :pending_review)
    first = Product.find(product.id)
    second = Product.find(product.id)

    described_class.call(product: first, reviewer: admin)

    expect { Products::Reject.call(product: second, reviewer: create(:user, :admin), reason: "ตัดสินช้าไปแล้ว") }
      .to raise_error(Product::InvalidTransition)
    expect(product.reload).to be_approved
    expect(product.reviews.count).to eq(1)
  end
end
