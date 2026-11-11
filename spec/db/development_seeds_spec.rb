require "rails_helper"

RSpec.describe "Development seeds", type: :task do
  let(:seller_account) { DevLogin::ACCOUNTS.fetch("seller") }
  let(:admin_account) { DevLogin::ACCOUNTS.fetch("admin") }

  def seed! = load Rails.root.join("db/seeds/development.rb")

  before do
    allow($stdout).to receive(:puts)
    travel_to(Time.zone.local(2026, 11, 11, 12, 0)) # seed ใช้เวลาย้อนหลังจากตอนนี้ — ตรึงไว้กันผันผวนช่วงเที่ยงคืน
  end

  it "creates the seller and the admin with the right roles" do
    seed!

    roles = User.where(uid: [ seller_account[:uid], admin_account[:uid] ]).to_h { |user| [ user.email, user.role ] }

    expect(roles).to eq("seller@example.test" => "user", "admin@example.test" => "admin")
  end

  it "gives the seller a product in every status" do
    seed!

    seller = User.find_by!(uid: seller_account[:uid])

    expect(seller.products.group(:status).count).to eq("draft" => 1, "pending_review" => 2, "approved" => 1, "rejected" => 1)
  end

  it "fills the admin queue with an overdue item, a resubmission and one decision made today" do
    seed!

    stats = Admin::ReviewQueueStats.new

    expect([ stats.pending, stats.overdue, stats.resubmitted, stats.reviewed_today ]).to eq([ 4, 1, 1, 1 ])
  end

  it "gives the rejected product a reason the seller can read" do
    seed!

    rejected = Product.find_by!(title: "ภาพวาดสีน้ำมันชายทะเล")

    expect(rejected.latest_rejection.reason).to include("รูปไม่ชัด")
  end

  it "is safe to run again" do
    seed!

    expect { seed! }.not_to change { [ User.count, Product.count, ProductReview.count ] }
  end

  it "leaves data the developer added themselves alone" do
    seed!
    mine = create(:product, seller: User.find_by!(uid: seller_account[:uid]), title: "ของที่ฉันลงเอง")

    seed!

    expect(mine.reload.title).to eq("ของที่ฉันลงเอง")
  end

  describe "with the fake login" do
    def login_as(account)
      auth = OmniAuth::AuthHash.new(provider: "keycloak", uid: account[:uid], info: { email: account[:email], name: account[:name] })
      User.from_omniauth(auth)
    end

    it "signs in as the seeded admin and keeps the admin role" do
      seed!

      expect(login_as(admin_account)).to be_admin
    end

    it "signs in as the seeded seller without creating a second account" do
      seed!

      expect { login_as(seller_account) }.not_to change(User, :count)
    end
  end
end
