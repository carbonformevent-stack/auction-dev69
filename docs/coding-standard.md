# Coding Standard

## RuboCop

- Config: [.rubocop.yml](../.rubocop.yml) — base คือ `rubocop-rails-omakase` (รวม **rubocop-rails** และ rubocop-performance) + **rubocop-rspec** + rubocop-rspec_rails
- CI รัน `bin/rubocop` ทุก PR — มี offense = CI แดง
- แก้อัตโนมัติ: `bin/rubocop -A` (ตรวจ diff ก่อน commit เสมอ)
- จะ disable cop ต้องมีเหตุผลใน comment และขอบเขตแคบที่สุด (`# rubocop:disable X -- เหตุผล` ... `# rubocop:enable X`)
- การเปลี่ยน `.rubocop.yml` ต้องคุยในทีมและแยกเป็น PR ของตัวเอง

## การตั้งชื่อ

| สิ่งที่ตั้งชื่อ | รูปแบบ | ตัวอย่าง |
|---|---|---|
| Model | เอกพจน์, CamelCase | `Product`, `Auction`, `Bid`, `ProductReview` |
| Table | พหูพจน์, snake_case | `products`, `product_reviews` |
| Controller | พหูพจน์ | `ProductsController`, `Admin::ReviewsController` |
| Service | คำกริยา + นาม | `Products::Submit`, `Auctions::Close`, `Bids::Place` |
| Boolean method | ลงท้าย `?` | `editable?`, `bids_visible?` |
| Method ที่ raise / เปลี่ยน state อันตราย | ลงท้าย `!` | `validate_bid!`, `approve!` |
| Enum | สถานะเป็น snake_case | `pending_review`, `in_progress` |
| เงิน | integer หน่วย **บาท** (MVP ไม่มีสตางค์), ชื่อลงท้ายด้วยความหมาย | `starting_price`, `amount` |
| เวลา | `_at` สำหรับ datetime, `_on` สำหรับ date | `starts_at`, `reviewed_at` |

- โค้ด ชื่อตัวแปร ชื่อ method ใช้ภาษาอังกฤษ — comment และข้อความใน UI ใช้ภาษาไทยได้
- ข้อความที่ผู้ใช้เห็นควรอยู่ใน `config/locales` เมื่อเริ่มมีหลายหน้า

## โครงสร้างและที่อยู่ของ logic

```
app/
  models/        # validation, association, scope, state ของตัวเอง
  services/      # business process ที่แตะหลาย model หรือมี side effect
  controllers/   # รับ request → เรียก service/model → render/redirect (บาง ๆ)
  views/         # แสดงผลเท่านั้น
  helpers/       # format ค่าเพื่อแสดงผล (ราคา, badge สถานะ)
  jobs/          # Solid Queue jobs — เรียก service อีกที
  policies/      # (ถ้าต้องการ) กฎสิทธิ์ที่ซับซ้อนกว่า admin?/owner?
```

### Service object

ใช้เมื่อ: process มีหลายขั้น, แตะหลาย model, มี side effect (ส่งอีเมล, enqueue job), หรือต้องใช้ transaction

```ruby
# app/services/products/approve.rb
module Products
  class Approve
    def self.call(...) = new(...).call

    def initialize(product:, reviewer:)
      @product = product
      @reviewer = reviewer
    end

    def call
      Product.transaction do
        # UPDATE ... WHERE status = pending_review — 0 แถว = มีคนตัดสินไปแล้ว → raise
        @product.transition!(from: :pending_review, to: :approved)
        @product.reviews.create!(reviewer: @reviewer, decision: :approved)
      end
      @product
    end
  end
end
```

กติกา:
- 1 class = 1 หน้าที่, public method เดียวคือ `call`
- รับ dependency ผ่าน keyword arguments
- ล้มเหลวให้ raise exception ที่ตั้งชื่อชัด หรือคืน result object — เลือกแบบเดียวกันทั้งโปรเจกต์ (ตั้งต้น: raise)
- ใช้ transaction + conditional update (`UPDATE ... WHERE status = ...` แล้วเช็กจำนวนแถว เช่น `Product#transition!`) เมื่อเปลี่ยน state ที่แข่งกันได้ (อนุมัติ, เสนอราคา, ปิดประมูล) — SQLite ไม่รองรับ `SELECT ... FOR UPDATE` จึง `lock!` ไม่มีผล

### ห้าม logic ใน view

- View ห้าม query database (`Product.where(...)`), ห้ามตัดสินใจทาง business (`if product.status == "approved" && current_user.id == product.seller_id`)
- ให้ย้ายไป model method (`product.editable_by?(user)`), helper (`status_badge(product)`), หรือ presenter
- Controller เตรียม data ให้ครบ และใช้ `includes` กัน N+1

## UI Design (ข้อกำหนดกลาง)

- **แหล่งอ้างอิงเดียว** ของการออกแบบ UI ทุกหน้าคือ [Design canvas](https://claude.ai/artifact/QQMiqYfRigdsJ1rj4E4jLn#page-dcb81aee8d83) — แนวทาง **B · Modern marketplace**
- ห้ามออกแบบหน้าใหม่หรือเปลี่ยน layout, สี, ตัวอักษร, component ตามแหล่งอื่น (screenshot, เว็บอื่น, ความชอบส่วนตัว, ข้อเสนอของ AI) — ถ้า design ยังไม่มีหน้าที่ต้องทำ ให้เพิ่มหน้าใน design canvas ก่อน แล้วค่อยลงมือ
- สี ระยะ และตัวอักษรใช้ token ใน [app/assets/tailwind/application.css](../app/assets/tailwind/application.css) ซึ่งต้องตรงกับ design — ห้าม hard-code ค่าสีหรือขนาดใน view
- ถ้าจำเป็นต้องทำต่างจาก design (เช่น ขัดกับ Acceptance Criteria หรือยังไม่มี backend รองรับ) ให้เขียนเหตุผลไว้ใน PR หัวข้อ "สิ่งที่ไม่ตาม design"
- PR ที่มี UI ให้แนบ screenshot เทียบกับหน้าใน design canvas

## Database

- ทุก business rule ที่สำคัญต้องมี constraint ใน DB ด้วย ไม่ใช่แค่ validation (เช่น unique index `bids(auction_id, user_id)`, `NOT NULL`, check constraint ช่วงราคา)
- Foreign key ทุกความสัมพันธ์ (`t.references ..., foreign_key: true`)
- Migration ต้องย้อนกลับได้ (`change` หรือ `up`/`down`)
- เก็บเวลาเป็น UTC ใน DB, แสดงผลเป็น `Asia/Bangkok` (ตั้งไว้แล้วใน `config.time_zone`)

## Testing (RSpec)

- Test อยู่ใน `spec/` แบ่งตามชนิด: `models/`, `services/`, `requests/`, `jobs/`, `system/` (เมื่อจำเป็น)
- ใช้ FactoryBot (`create`, `build`) — ไม่ใช้ fixtures
- 1 `it` = 1 พฤติกรรม, ชื่อ `it` อ่านแล้วเป็นประโยค
- Boundary ใน Acceptance Criteria ต้องมี test ตรงตัว (เช่น ราคา 0, 1, 20000, 20001)
- Request spec สำหรับทุก endpoint: guest, user ทั่วไป, เจ้าของ, admin
- ห้ามต่อ service ภายนอกจริงใน test (Keycloak ใช้ OmniAuth mock, S3 ใช้ Disk service)

## Security

- Secret อ่านจาก ENV / Rails credentials เท่านั้น ห้าม commit `.env`, `config/master.key`
- ใช้ strong parameters เสมอ, ห้าม `permit!`
- ตรวจสิทธิ์ที่ controller ทุก action (เจ้าของสินค้า / admin) — อย่าพึ่งการซ่อนปุ่มใน UI
- ราคาประมูลที่ยังไม่ปิดต้องไม่หลุดผ่าน JSON, log หรือ HTML
