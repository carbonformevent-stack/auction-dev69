# System spec ใช้ Cuprite (headless Chrome) — ไม่ต้องมี chromedriver
require "capybara/rspec"
require "capybara/cuprite"

DESKTOP_SIZE = [ 1280, 900 ].freeze
MOBILE_SIZE = [ 390, 844 ].freeze

Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(
    app,
    window_size: DESKTOP_SIZE,
    headless: true,
    # CI (Linux container) ต้องปิด sandbox ของ Chrome
    browser_options: ENV["CI"] ? { "no-sandbox" => nil } : {},
    process_timeout: 20,
    timeout: 10
  )
end

Capybara.javascript_driver = :cuprite
Capybara.default_max_wait_time = 3
# ค้นปุ่ม/ลิงก์ด้วย aria-label ได้ — ตรงกับชื่อที่ screen reader อ่านให้ผู้ใช้
Capybara.enable_aria_label = true
Capybara.server = :puma, { Silent: true }

module BrowserHelpers
  def resize_to_mobile = page.driver.resize(*MOBILE_SIZE)
  def resize_to_desktop = page.driver.resize(*DESKTOP_SIZE)

  # บันทึกภาพหน้าจอไว้แนบ PR — tmp/screenshots/<ชื่อ>.png
  def snap(name)
    path = Rails.root.join("tmp/screenshots/#{name}.png")
    FileUtils.mkdir_p(path.dirname)
    page.driver.save_screenshot(path.to_s, full: true)
  end

  def horizontal_overflow?
    page.evaluate_script("document.documentElement.scrollWidth > document.documentElement.clientWidth")
  end
end

RSpec.configure do |config|
  config.include BrowserHelpers, type: :system

  config.before(:each, type: :system) { driven_by :cuprite }
  # ไฟล์ที่อัปโหลดและ Active Storage ใช้ service :test เหมือน request spec
  config.after(:each, type: :system) { resize_to_desktop }
end
