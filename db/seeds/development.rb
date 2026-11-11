# บัญชีและสินค้าตัวอย่างสำหรับ local development — โหลดจาก db/seeds.rb เฉพาะ development เท่านั้น
# รันซ้ำได้: ไม่สร้างข้อมูลซ้ำ (หาจากอีเมล/ชื่อสินค้า) และไม่แก้ข้อมูลที่ผู้ใช้ทำเพิ่มเอง
#
# เข้าระบบด้วยบัญชีเหล่านี้: ตั้ง DEV_LOGIN=1 ใน .env แล้วกดปุ่มบนหน้า /sign_in (ดู config/initializers/dev_login.rb)
require_relative "../../lib/dev_login"

fixtures = Rails.root.join("spec/fixtures/files")
photos = %w[image.jpg image.png image.webp].map { |name| fixtures.join(name) }

upsert_user = lambda do |account|
  User.find_or_initialize_by(provider: "keycloak", uid: account[:uid]).tap do |user|
    user.update!(email: account[:email], name: account[:name], role: account[:role])
  end
end

seller = upsert_user.call(DevLogin::ACCOUNTS.fetch("seller"))
admin = upsert_user.call(DevLogin::ACCOUNTS.fetch("admin"))
other = upsert_user.call(DevLogin::OTHER_SELLER)

# สร้างสินค้าแล้วตั้งสถานะตรง ๆ (ข้าม state machine — นี่คือข้อมูลตั้งต้น ไม่ใช่การใช้งานจริง)
build_product = lambda do |owner, title, category:, price:, status:, submitted_ago: nil, photo_count: 2|
  Product.find_by(seller: owner, title: title) || Product.new(
    seller: owner, title: title, category: category, starting_price: price, desired_duration_minutes: 4320,
    description: "#{title}\nสภาพสมบูรณ์ ใช้งานได้ปกติ มีรอยตามอายุการใช้งานเล็กน้อย เก็บรักษาอย่างดีโดยเจ้าของเดิม"
  ).tap do |product|
    photos.first(photo_count).each { |path| product.images.attach(io: path.open, filename: path.basename.to_s) }
    product.save!
    product.update_columns(status: Product.statuses.fetch(status.to_s), submitted_at: submitted_ago&.ago)
  end
end

review = lambda do |product, decision, reason: nil, ago: 1.hour|
  next if product.reviews.exists?(decision: decision)

  ProductReview.create!(product: product, reviewer: admin, decision: decision, reason: reason, created_at: ago.ago)
end

# ── ของผู้ขายทดสอบ ครบทุกสถานะ ─────────────────────────────────────────────
build_product.call(seller, "นาฬิกาพกเงินแท้ ลายสลัก", category: :watch, price: 4_500, status: :draft, photo_count: 1)
build_product.call(seller, "แหวนทองคำโบราณ", category: :jewelry, price: 12_000, status: :pending_review, submitted_ago: 3.hours)

approved = build_product.call(seller, "หนังสือพิมพ์ฉบับแรก ปี 2475", category: :old_book, price: 800,
                                                                      status: :approved, submitted_ago: 2.days)
review.call(approved, :approved, ago: 5.minutes) # ให้การ์ด "ตรวจแล้ววันนี้" ของ Admin มีตัวเลข

rejected = build_product.call(seller, "ภาพวาดสีน้ำมันชายทะเล", category: :painting, price: 15_000,
                                                               status: :rejected, submitted_ago: 2.days)
review.call(rejected, :rejected, reason: "รูปไม่ชัด ขอรูปด้านหลังกรอบภาพและลายเซ็นศิลปินเพิ่ม", ago: 1.day)

resubmitted = build_product.call(seller, "ตลับเงินลายดอกไม้", category: :jewelry, price: 6_000,
                                                              status: :pending_review, submitted_ago: 1.hour)
review.call(resubmitted, :rejected, reason: "ข้อมูลไม่ครบ ไม่ระบุที่มาและอายุของตลับ", ago: 1.day)

# ── ของผู้ขายอีกคน ทำให้คิว Admin มีรายการหลากหลาย (มีรายการที่รอเกิน 48 ชม.) ──
build_product.call(other, "สร้อยทองคำเก่า", category: :jewelry, price: 9_000, status: :pending_review, submitted_ago: 70.hours)
build_product.call(other, "นาฬิกาปลุกโบราณ", category: :watch, price: 2_500, status: :pending_review, submitted_ago: 20.hours)

puts "Seeded dev data: #{User.count} users, #{Product.count} products " \
     "(login: seller=#{DevLogin::ACCOUNTS['seller'][:email]}, admin=#{DevLogin::ACCOUNTS['admin'][:email]})"
