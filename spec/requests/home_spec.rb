require "rails_helper"

RSpec.describe "Home" do
  describe "GET /" do
    context "when signed out" do
      before { get root_path }

      it "is public and shows the hero" do
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("ของสะสมมีค่า")
      end

      it "shows sign in and sign up links pointing to the sign in page" do
        expect(response.body).to include(%(href="#{new_user_session_path}">เข้าสู่ระบบ</a>))
        expect(response.body).to include("สมัครสมาชิก")
      end

      it "lists all four categories" do
        %w[นาฬิกา เครื่องประดับ หนังสือเก่า ภาพวาด].each do |label|
          expect(response.body).to include(label)
        end
      end

      it "shows the seller limits from the product rules" do
        expect(response.body).to include("฿1").and include("฿20,000").and include("สูงสุด 12 รูป")
      end

      it "has anchors for the how-it-works and FAQ sections" do
        expect(response.body).to include(%(id="how-it-works")).and include(%(id="faq"))
      end
    end

    context "when signed in" do
      let(:user) { create(:user, name: "ณัฐพล") }

      before do
        sign_in user
        get root_path
      end

      it "shows the account menu instead of the sign in links" do
        expect(response.body).to include("บัญชีของฉัน")
        expect(response.body).not_to include("สมัครสมาชิก")
      end
    end
  end
end
