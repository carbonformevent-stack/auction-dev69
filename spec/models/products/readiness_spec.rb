require "rails_helper"

RSpec.describe Products::Readiness do
  def readiness(product) = described_class.new(product)

  def status_of(product, key) = readiness(product).steps.find { |step| step.key == key }.status

  describe "#steps" do
    it "lists the five listing steps in order" do
      keys = readiness(build(:product)).steps.map(&:key)

      expect(keys).to eq(%i[category details images certificate price_and_time])
    end
  end

  describe "category step" do
    it "is done when a category is chosen" do
      expect(status_of(build(:product, category: :watch), :category)).to eq(:done)
    end

    it "is todo when no category is chosen" do
      expect(status_of(build(:product, category: nil), :category)).to eq(:todo)
    end
  end

  describe "details step" do
    it "is done when title and description are present" do
      expect(status_of(build(:product), :details)).to eq(:done)
    end

    it "is todo when the description is blank" do
      expect(status_of(build(:product, description: ""), :details)).to eq(:todo)
    end

    it "is todo when the title is blank" do
      expect(status_of(build(:product, title: ""), :details)).to eq(:todo)
    end
  end

  describe "images step" do
    it "is todo with no images" do
      expect(status_of(build(:product), :images)).to eq(:todo)
    end

    it "is done with at least one image" do
      expect(status_of(build(:product, :with_image), :images)).to eq(:done)
    end
  end

  describe "certificate step" do
    it "is optional while nothing is attached" do
      expect(status_of(build(:product), :certificate)).to eq(:optional)
    end

    it "is done once a PDF is attached" do
      product = build(:product)
      product.certificate.attach(io: StringIO.new("%PDF-1.4"), filename: "c.pdf", content_type: "application/pdf")

      expect(status_of(product, :certificate)).to eq(:done)
    end
  end

  describe "price_and_time step" do
    [ 1, 20_000 ].each do |price|
      it "is done at the boundary price #{price}" do
        expect(status_of(build(:product, starting_price: price), :price_and_time)).to eq(:done)
      end
    end

    [ 0, 20_001, nil ].each do |price|
      it "is todo for the invalid price #{price.inspect}" do
        expect(status_of(build(:product, starting_price: price), :price_and_time)).to eq(:todo)
      end
    end

    it "is todo when the duration is out of range" do
      expect(status_of(build(:product, desired_duration_minutes: 30), :price_and_time)).to eq(:todo)
    end
  end

  describe "#done_count and #total" do
    it "counts done steps out of five" do
      result = readiness(build(:product, :with_image))

      expect([ result.done_count, result.total ]).to eq([ 4, 5 ])
    end
  end

  describe "#ready_to_submit?" do
    it "is true when every required step is done even without a certificate" do
      expect(readiness(build(:product, :with_image))).to be_ready_to_submit
    end

    it "is false when a required step is todo" do
      expect(readiness(build(:product))).not_to be_ready_to_submit
    end
  end

  describe "#current_step" do
    it "is the first step that is not done" do
      expect(readiness(build(:product)).current_step).to eq(:images)
    end

    it "is nil when everything is done" do
      product = build(:product, :with_image)
      product.certificate.attach(io: StringIO.new("%PDF-1.4"), filename: "c.pdf", content_type: "application/pdf")

      expect(readiness(product).current_step).to be_nil
    end
  end
end
