require "rails_helper"

# Design canvas หน้า "6 · สร้างการประมูล"
RSpec.describe "Admin creates an auction in a browser (#20)" do
  let(:admin) { create(:user, :admin) }
  let!(:product) do
    create(:product, :approved, title: "แหวนพลอยไพลินกาญจนบุรี", starting_price: 12_000, desired_duration_minutes: 4320)
  end
  let(:start) { 2.days.from_now.to_date.in_time_zone.change(hour: 20) }

  before { sign_in admin }

  def fill_in_start
    fill_in "วันที่เริ่ม", with: start.to_date
    fill_in "เวลาเริ่ม", with: "20:00"
  end

  it "opens from the approved product with the seller's duration and the copied price" do
    visit admin_product_path(product)
    click_link "สร้างการประมูล"

    expect(page).to have_css("h1", text: "สร้างการประมูล")
    expect(page).to have_field("ราคาเริ่มต้น", with: "12,000", readonly: true)
    expect(page).to have_checked_field("3 วัน · ผู้ขายเสนอ", visible: :all)
  end

  it "updates the close time and the summary when the admin picks another duration" do
    visit new_admin_product_auction_path(product)
    fill_in_start

    find("label", text: "1 วัน", exact_text: true).click

    within("aside") { expect(page).to have_text("1 วัน") }
    expect(page).to have_text(ApplicationController.helpers.thai_datetime_full(start + 1.day))
  end

  it "creates a scheduled auction and lists it" do
    visit new_admin_product_auction_path(product)
    fill_in_start
    find("label", text: "1 วัน", exact_text: true).click

    click_button "สร้างการประมูล"

    expect(page).to have_text("สร้างการประมูลแล้ว · สถานะ “กำหนดการ” จะเปิดรับราคาอัตโนมัติ")
    expect(page).to have_css("[data-auction]", text: "กำหนดการ")
    expect(product.auctions.last).to have_attributes(status: "scheduled", starts_at: start, ends_at: start + 1.day)
  end

  it "warns right away when the start time is in the past" do
    visit new_admin_product_auction_path(product)

    fill_in "วันที่เริ่ม", with: Date.current
    fill_in "เวลาเริ่ม", with: "00:00"

    expect(page).to have_css("[role='alert']", text: "เวลาเริ่มต้องอยู่หลังเวลาปัจจุบัน")
  end

  it "cancels a scheduled auction after confirming, and the product is ready again" do
    auction = create(:auction, product: product)
    visit admin_auctions_path

    accept_confirm { click_button "ยกเลิกการประมูล #{product.title}" }

    expect(page).to have_css("[data-auction='#{auction.id}']", text: "ยกเลิกแล้ว")
    expect(page).to have_css("[data-ready-product='#{product.id}']")
  end
end
