require "rails_helper"

# FPSBA ซ่อนราคาทุกคนจนปิดประมูล (#23): ราคาเสนอต้องไม่หลุดลง log
RSpec.describe "Bid amount log filtering" do
  let(:log) { StringIO.new }

  around do |example|
    original = ActionController::Base.logger
    ActionController::Base.logger = ActiveSupport::Logger.new(log)
    example.run
  ensure
    ActionController::Base.logger = original
  end

  it "filters bid amounts from request parameters in the log" do
    get root_path, params: { bid: { amount: 98_765 } }

    expect(log.string).to include("[FILTERED]")
    expect(log.string).not_to include("98765")
  end

  it "keeps the public starting price visible in the log" do
    get root_path, params: { product: { starting_price: 4_321 } }

    expect(log.string).to include("4321")
  end
end
