require "rails_helper"

# พิสูจน์ว่าโครงสร้าง system spec (Cuprite + Devise sign_in + Tailwind build) ใช้งานได้
RSpec.describe "Browser smoke" do
  it "renders the seller product list in a real browser after sign in" do
    seller = create(:user)
    create(:product, :approved, seller: seller, title: "นาฬิกาพกโบราณ")
    sign_in seller

    visit products_path

    expect(page).to have_css("h1", text: "สินค้าของฉัน")
    expect(page).to have_content("นาฬิกาพกโบราณ")
  end

  it "redirects guests to the sign in page" do
    visit products_path

    expect(page).to have_current_path(new_user_session_path)
  end
end
