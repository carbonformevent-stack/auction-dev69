# System spec ใช้ Cuprite (headless Chrome) — ไม่ต้องมี chromedriver
require "capybara/rspec"
require "capybara/cuprite"

DESKTOP_SIZE = [ 1280, 900 ].freeze
MOBILE_SIZE = [ 390, 844 ].freeze

# ตัวเลือกของ Chrome ต้องส่งผ่าน `driven_by ... options:` เท่านั้น
# (Capybara.register_driver เองไม่พอ: driven_by :cuprite ของ Rails ลงทะเบียนไดรเวอร์ชื่อเดิมทับทุกครั้ง
#  ด้วยตัวเลือกของมันเอง ทำให้ค่าที่ตั้งไว้ที่อื่นหายไปเงียบ ๆ — เคยทำให้ Chrome เปิดไม่ขึ้นบน CI)
# คืน hash ใหม่ทุกครั้ง เพราะ Rails แก้ hash ที่รับไป (options.delete(:name))
def cuprite_options
  {
    headless: true,
    # GitHub Actions (Ubuntu) จำกัด sandbox ของ Chrome — ต้องปิดบน CI ไม่งั้นเปิดไม่ขึ้น (ดู spec/system/browser_config_spec.rb)
    browser_options: ENV["CI"] ? { "no-sandbox" => nil } : {},
    process_timeout: 30,
    timeout: 15
  }
end

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

  config.before(:each, type: :system) { driven_by :cuprite, screen_size: DESKTOP_SIZE, options: cuprite_options }
  # ไฟล์ที่อัปโหลดและ Active Storage ใช้ service :test เหมือน request spec
  config.after(:each, type: :system) { resize_to_desktop }
end
