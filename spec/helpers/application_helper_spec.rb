require "rails_helper"

RSpec.describe ApplicationHelper do
  describe "#avatar_initial" do
    it "uses the first letter of the display name" do
      expect(helper.avatar_initial(build(:user, name: "ณัฐพล"))).to eq("ณ")
    end

    it "skips Thai leading vowels so the initial is a consonant" do
      expect(helper.avatar_initial(build(:user, name: "เอกชัย"))).to eq("อ")
    end

    it "upcases latin letters" do
      expect(helper.avatar_initial(build(:user, name: "alice"))).to eq("A")
    end

    it "falls back to the email when there is no name" do
      expect(helper.avatar_initial(build(:user, name: nil, email: "zed@example.com"))).to eq("Z")
    end
  end

  describe "#admin_area?" do
    it "is true for controllers in the admin namespace" do
      allow(helper).to receive(:controller_path).and_return("admin/products")

      expect(helper).to be_admin_area
    end

    it "is false elsewhere" do
      allow(helper).to receive(:controller_path).and_return("products")

      expect(helper).not_to be_admin_area
    end
  end
end
