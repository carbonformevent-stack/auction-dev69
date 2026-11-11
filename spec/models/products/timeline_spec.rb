require "rails_helper"

RSpec.describe Products::Timeline do
  let(:admin) { build(:user, :admin, name: "สมชาย แอดมิน") }
  let(:t0) { Time.zone.local(2026, 11, 7, 14, 2) }

  def add_review(product, decision, at:, reason: nil)
    product.reviews.build(reviewer: admin, decision: decision, reason: reason, created_at: at)
  end

  def timeline(product, audience: :seller) = described_class.new(product, audience: audience).events

  def labels(product, **) = timeline(product, **).map(&:label)

  it "starts with the draft creation" do
    product = build(:product, created_at: t0)

    expect(labels(product)).to eq([ "สร้างฉบับร่าง" ])
  end

  it "adds the submission with its time for a pending product" do
    product = build(:product, :pending_review, created_at: t0, submitted_at: t0 + 1.day)

    expect(timeline(product).map { |event| [ event.label, event.at ] })
      .to eq([ [ "สร้างฉบับร่าง", t0 ], [ "ส่งตรวจสอบ", t0 + 1.day ] ])
  end

  it "shows the submission before the review that followed it" do
    product = build(:product, :rejected, created_at: t0, submitted_at: t0 + 1.day)
    add_review(product, :rejected, at: t0 + 2.days, reason: "รูปไม่ชัด")

    expect(labels(product)).to eq([ "สร้างฉบับร่าง", "ส่งตรวจสอบ", "ไม่อนุมัติ" ])
  end

  it "labels the resubmission of a pending product after a rejection" do
    product = build(:product, :pending_review, created_at: t0, submitted_at: t0 + 3.days)
    add_review(product, :rejected, at: t0 + 2.days, reason: "รูปไม่ชัด")

    expect(labels(product)).to eq([ "สร้างฉบับร่าง", "ส่งตรวจสอบ", "ไม่อนุมัติ", "ส่งใหม่ รอตรวจสอบ" ])
  end

  it "does not invent the time of an earlier submission that was not recorded" do
    product = build(:product, :pending_review, created_at: t0, submitted_at: t0 + 3.days)
    add_review(product, :rejected, at: t0 + 2.days, reason: "รูปไม่ชัด")

    first_submission = timeline(product).find { |event| event.label == "ส่งตรวจสอบ" }

    expect(first_submission.at).to be_nil
  end

  it "tells the whole story of a product approved after a resubmission" do
    product = build(:product, :approved, created_at: t0, submitted_at: t0 + 3.days)
    add_review(product, :rejected, at: t0 + 2.days, reason: "รูปไม่ชัด")
    add_review(product, :approved, at: t0 + 4.days)

    expect(labels(product)).to eq([ "สร้างฉบับร่าง", "ส่งตรวจสอบ", "ไม่อนุมัติ", "ส่งใหม่", "อนุมัติแล้ว" ])
  end

  it "keeps the known submission time for the latest round only" do
    product = build(:product, :approved, created_at: t0, submitted_at: t0 + 3.days)
    add_review(product, :rejected, at: t0 + 2.days, reason: "รูปไม่ชัด")
    add_review(product, :approved, at: t0 + 4.days)

    times = timeline(product).select { |event| event.kind.in?(%i[submitted resubmitted]) }.map(&:at)

    expect(times).to eq([ nil, t0 + 3.days ])
  end

  it "still shows the submission of a legacy product that has no review record" do
    product = build(:product, :approved, created_at: t0, submitted_at: t0 + 1.day)

    expect(labels(product)).to eq([ "สร้างฉบับร่าง", "ส่งตรวจสอบ" ])
  end

  describe "audience" do
    let(:product) do
      build(:product, :rejected, created_at: t0, submitted_at: t0 + 1.day).tap do |built|
        add_review(built, :rejected, at: t0 + 2.days, reason: "รูปไม่ชัด")
      end
    end

    it "never exposes the reviewer to the seller" do
      review_event = timeline(product, audience: :seller).find { |event| event.kind == :rejected }

      expect(review_event.reviewer).to be_nil
    end

    it "gives admins the reviewer and the reason" do
      review_event = timeline(product, audience: :admin).find { |event| event.kind == :rejected }

      expect([ review_event.reviewer, review_event.reason ]).to eq([ admin, "รูปไม่ชัด" ])
    end

    it "rejects an unknown audience" do
      expect { described_class.new(product, audience: :guest) }.to raise_error(ArgumentError)
    end
  end
end
