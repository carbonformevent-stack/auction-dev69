require "rails_helper"

RSpec.describe "Home page" do
  context "when signed out on mobile (390px)" do
    before do
      resize_to_mobile
      visit root_path
    end

    it "does not scroll sideways" do
      expect(horizontal_overflow?).to be(false)
    end

    it "keeps the sign in button reachable and hides the section menu" do
      expect(page).to have_link("เข้าสู่ระบบ", href: new_user_session_path)
      expect(page).to have_no_css("nav[aria-label='เมนูหลัก']", visible: :visible)
    end
  end

  context "when signed out on desktop" do
    before { visit root_path }

    it "links the header menu to the sections on this page" do
      within("nav[aria-label='เมนูหลัก']") do
        expect(page).to have_link("วิธีประมูล", href: root_path(anchor: "how-it-works"))
        expect(page).to have_link("คำถามที่พบบ่อย", href: root_path(anchor: "faq"))
      end
      expect(page).to have_css("#how-it-works").and have_css("#faq")
    end

    it "opens the first FAQ answer and expands another on click" do
      expect(page).to have_content("แต่ละคนเสนอราคาได้ครั้งเดียว")
      expect(page).to have_no_content("ผู้ที่เสนอราคานั้นก่อนเป็นผู้ชนะ")

      find("summary", text: "ถ้ามีคนเสนอราคาเท่ากันจะเป็นอย่างไร").click

      expect(page).to have_content("ผู้ที่เสนอราคานั้นก่อนเป็นผู้ชนะ")
    end
  end
end
