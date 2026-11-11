require "rails_helper"

RSpec.describe Products::Submit do
  let(:seller) { create(:user) }

  it "moves a complete draft to pending_review and records the time (#13 AC1)" do
    product = create(:product, :with_image, seller: seller)

    freeze_time do
      described_class.call(product: product, user: seller)

      expect(product).to be_pending_review
      expect(product.submitted_at).to eq(Time.current)
    end
  end

  it "refuses a draft without images and keeps it draft (#13 AC2)" do
    product = create(:product, seller: seller)

    expect { described_class.call(product: product, user: seller) }
      .to raise_error(ActiveRecord::RecordInvalid, /ต้องมีรูปอย่างน้อย 1 รูป/)
    expect(product.reload).to be_draft
  end

  it "refuses another user (#13 AC3)" do
    product = create(:product, :with_image, seller: seller)

    expect { described_class.call(product: product, user: create(:user)) }
      .to raise_error(ActiveRecord::RecordNotFound)
    expect(product.reload).to be_draft
  end

  it "does not change pending_review or approved products (#13 AC4)" do
    %i[pending_review approved].each do |status|
      product = create(:product, status, seller: seller)

      expect { described_class.call(product: product, user: seller) }.to raise_error(Product::InvalidTransition)
      expect(product.reload.status).to eq(status.to_s)
    end
  end

  it "resubmits a rejected product to the queue (#18 AC4)" do
    product = create(:product, :rejected, seller: seller)

    described_class.call(product: product, user: seller)

    expect(Product.review_queue).to include(product)
  end
end
