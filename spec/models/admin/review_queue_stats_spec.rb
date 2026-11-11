require "rails_helper"

RSpec.describe Admin::ReviewQueueStats do
  subject(:stats) { described_class.new }

  let(:now) { Time.zone.local(2026, 11, 11, 12, 0) }

  before { travel_to(now) }

  describe "#pending" do
    it "counts only products waiting for review" do
      create(:product, :pending_review)
      create(:product, :approved)
      create(:product)

      expect(stats.pending).to eq(1)
    end
  end

  describe "#overdue" do
    it "counts products that waited more than 48 hours" do
      create(:product, :pending_review, submitted_at: now - 48.hours - 1.second)

      expect(stats.overdue).to eq(1)
    end

    it "does not count exactly 48 hours" do
      create(:product, :pending_review, submitted_at: now - 48.hours)

      expect(stats.overdue).to eq(0)
    end

    it "ignores products that are no longer pending" do
      create(:product, :approved, submitted_at: now - 5.days)

      expect(stats.overdue).to eq(0)
    end
  end

  describe "#resubmitted" do
    it "counts pending products that were rejected before" do
      product = create(:product, :pending_review)
      create(:product_review, :rejected, product: product)
      create(:product, :pending_review)

      expect(stats.resubmitted).to eq(1)
    end

    it "counts a product once however many times it was rejected" do
      product = create(:product, :pending_review)
      create(:product_review, :rejected, product: product, created_at: 3.days.ago)
      create(:product_review, :rejected, product: product, created_at: 2.days.ago)

      expect(stats.resubmitted).to eq(1)
    end

    it "ignores rejected products that were not resubmitted" do
      product = create(:product, :rejected)
      create(:product_review, :rejected, product: product)

      expect(stats.resubmitted).to eq(0)
    end
  end

  describe "#reviewed_today" do
    it "counts approvals and rejections made today by any admin" do
      create(:product_review, created_at: now - 1.hour)
      create(:product_review, :rejected, created_at: now - 3.hours)

      expect(stats.reviewed_today).to eq(2)
    end

    it "does not count a review made just before midnight yesterday" do
      create(:product_review, created_at: Time.zone.local(2026, 11, 10, 23, 59))

      expect(stats.reviewed_today).to eq(0)
    end

    it "counts a review made just after midnight today" do
      create(:product_review, created_at: Time.zone.local(2026, 11, 11, 0, 1))

      expect(stats.reviewed_today).to eq(1)
    end
  end
end
