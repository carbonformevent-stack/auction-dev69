require "rails_helper"

# กันไม่ให้ตัวเลือก Chrome หายไปเงียบ ๆ อีก: ตรวจจากไดรเวอร์ที่ใช้งานจริง ไม่ใช่จากค่าที่ตั้งไว้
RSpec.describe "Browser configuration" do
  let(:chrome_options) { page.driver.browser.options }

  before { visit "/up" }

  it "gives Chrome enough time to start on a slow machine" do
    expect(chrome_options.process_timeout).to eq(30)
  end

  it "runs headless" do
    expect(chrome_options.headless).to be(true)
  end

  it "uses the desktop window size by default" do
    expect(chrome_options.window_size).to eq(DESKTOP_SIZE)
  end

  it "disables Chrome's sandbox on CI, where the runner does not allow it" do
    skip "ตรวจเฉพาะบน CI (ENV['CI'])" unless ENV["CI"]

    expect(chrome_options.browser_options).to include("no-sandbox" => nil)
  end
end
