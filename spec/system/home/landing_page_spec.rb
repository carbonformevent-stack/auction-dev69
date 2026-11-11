require "rails_helper"

RSpec.describe "Landing page" do
  it "shows live auctions first" do
    visit root_path

    expect(page).to have_css("[role='tabpanel']", text: "นาฬิกาพกโบราณ ปี 1920")
    expect(page).to have_no_css("[role='tabpanel']", text: "แหวนพลอยไพลิน ตัวเรือนทอง")
  end

  it "switches to upcoming auctions with the tabs" do
    visit root_path

    click_button "กำลังจะเริ่ม"

    expect(page).to have_css("[role='tabpanel']", text: "แหวนพลอยไพลิน ตัวเรือนทอง")
    expect(page).to have_no_css("[role='tabpanel']", text: "นาฬิกาพกโบราณ ปี 1920")
    expect(page).to have_css("[role='tab'][aria-selected='true']", text: "กำลังจะเริ่ม")
  end

  it "counts down the featured auction every second" do
    visit root_path

    countdown = find("[data-controller='countdown']")
    first = countdown.text

    expect(countdown).to have_no_text(first, exact: true, wait: 3)
  end

  it "opens and closes FAQ answers" do
    visit root_path

    expect(page).to have_text("ไม่ได้ครับ ในการประมูลแบบปิดผนึก")

    find("summary", text: "ใครเห็นราคาที่ฉันเสนอบ้าง").click

    expect(page).to have_text("ไม่มีใครเห็นราคาของคุณระหว่างประมูล")
  end

  it "validates the notify form without sending the email anywhere" do
    visit root_path

    click_button "รับแจ้งเตือน"
    expect(page).to have_text("กรุณากรอกอีเมลให้ถูกต้อง")

    fill_in "อีเมลของคุณ", with: "fan@example.com"
    click_button "รับแจ้งเตือน"
    expect(page).to have_text("เปิดให้ลงทะเบียนเร็ว ๆ นี้")
    expect(page).to have_current_path(root_path)
  end

  it "does not scroll sideways on mobile" do
    resize_to_mobile
    visit root_path

    expect(horizontal_overflow?).to be(false)
  end

  it "captures the landing page on desktop and mobile for review" do
    resize_to_desktop
    page.driver.resize(1440, 900)
    visit root_path
    snap("landing-desktop")
    resize_to_mobile
    visit root_path
    snap("landing-mobile")

    expect(File).to exist(Rails.root.join("tmp/screenshots/landing-mobile.png"))
  end
end
