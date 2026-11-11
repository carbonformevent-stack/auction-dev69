require "rails_helper"

RSpec.describe Products::Reject do
  let(:admin) { create(:user, :admin) }
  let(:product) { create(:product, :pending_review) }

  it "rejects with reason, reviewer and time (#18 AC1)" do
    described_class.call(product: product, reviewer: admin, reason: "รูปหน้าปัดเบลอ")

    expect(product).to be_rejected
    expect(product.latest_rejection).to have_attributes(reviewer: admin, reason: "รูปหน้าปัดเบลอ")
  end

  it "requires a reason that is not only whitespace (#18 AC2)" do
    [ "", "   " ].each do |reason|
      expect { described_class.call(product: product, reviewer: admin, reason: reason) }
        .to raise_error(ActiveRecord::RecordInvalid, /กรุณาระบุเหตุผล/)
    end
    expect(product.reload).to be_pending_review
  end

  it "does not change products that are not pending_review" do
    approved = create(:product, :approved)

    expect { described_class.call(product: approved, reviewer: admin, reason: "x") }
      .to raise_error(Product::InvalidTransition)
  end

  it "keeps a full history across reject then approve (#19 AC1)" do
    described_class.call(product: product, reviewer: admin, reason: "ขอรูปเพิ่ม")
    Products::Submit.call(product: product, user: product.seller)
    Products::Approve.call(product: product, reviewer: admin)

    expect(product.reload.reviews.map(&:decision)).to eq(%w[rejected approved])
  end
end
