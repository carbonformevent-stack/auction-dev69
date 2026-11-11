require "rails_helper"

RSpec.describe ProductReview do
  it { is_expected.to belong_to(:product) }
  it { is_expected.to belong_to(:reviewer).class_name("User") }

  describe "reason" do
    it "is required for a rejection" do
      review = build(:product_review, decision: :rejected, reason: "   ")

      expect(review).not_to be_valid
      expect(review.errors[:reason]).to include("กรุณาระบุเหตุผล")
    end

    it "is optional for an approval" do
      expect(build(:product_review, decision: :approved, reason: nil)).to be_valid
    end

    it "is stripped" do
      expect(build(:product_review, :rejected, reason: "  รูปเบลอ  ").reason).to eq("รูปเบลอ")
    end

    it "accepts 1,000 characters and rejects 1,001" do
      expect(build(:product_review, :rejected, reason: "ก" * 1000)).to be_valid
      expect(build(:product_review, :rejected, reason: "ก" * 1001)).not_to be_valid
    end

    it "is enforced by a database check constraint for rejections" do
      review = create(:product_review, :rejected)

      expect { described_class.where(id: review.id).update_all(reason: nil) }
        .to raise_error(ActiveRecord::StatementInvalid)
    end
  end

  describe "immutability (#19 AC2)" do
    let(:review) { create(:product_review) }

    it "cannot be updated" do
      expect { review.update!(reason: "แก้ไข") }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it "cannot be destroyed" do
      expect { review.destroy! }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end
  end
end
