require "rails_helper"

RSpec.describe "Home (landing page)" do
  describe "GET /" do
    it "is public and renders every section of the landing page" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("ของสะสมมีค่า", "เลือกตามหมวด", "การประมูล", "ประมูลแบบปิดผนึกทำงานอย่างไร",
                                       "มีของสะสมอยากขาย?", "คำถามที่พบบ่อย", "รับแจ้งเตือนเมื่อมีการประมูลใหม่")
    end

    it "anchors the header navigation to the page sections" do
      get root_path

      %w[auctions how-it-works sell faq].each do |section|
        expect(response.body).to include(%(href="##{section}"), %(id="#{section}"))
      end
    end

    it "offers sign in and sign up to guests" do
      get root_path

      expect(response.body).to include("เข้าสู่ระบบ", "สมัครสมาชิก", new_user_session_path)
      expect(response.body).not_to include('aria-label="บัญชีของฉัน"')
    end

    it "shows the account menu instead of sign in to signed in users" do
      sign_in create(:user, name: "ณัฐพล")

      get root_path

      expect(response.body).to include('aria-label="บัญชีของฉัน"', "สินค้าของฉัน")
      expect(response.body).not_to include(%(href="#{new_user_session_path}"))
    end

    it "states the seller limits from the product rules" do
      get root_path

      expect(response.body).to include("฿1", "฿20,000", "สูงสุด 12 รูป")
    end

    it "links the sell buttons to the new product form" do
      get root_path

      expect(response.body).to include(%(href="#{new_product_path}"))
    end
  end
end
