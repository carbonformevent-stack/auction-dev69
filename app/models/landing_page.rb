# เนื้อหาหน้าแรก (landing page)
# ยังไม่มีระบบประมูล (Auction) — รายการประมูลจึงเป็นข้อมูลตัวอย่างที่คำนวณเวลาจาก now
# เมื่อมี model Auction แล้วให้เปลี่ยน live_auctions / upcoming_auctions เป็น query จริง
class LandingPage
  Category = Data.define(:key, :examples)
  Auction = Data.define(:title, :category, :starting_price, :bidder_count, :image_label, :starts_at, :ends_at) do
    def live?(now = Time.current) = starts_at <= now && now < ends_at
    def closing_soon?(now = Time.current) = live?(now) && ends_at - now < 1.hour
  end
  Step = Data.define(:title, :body)
  Faq = Data.define(:question, :answer)

  CATEGORIES = [
    Category.new(key: "watch", examples: "นาฬิกาพก ข้อมือ ตั้งโต๊ะ"),
    Category.new(key: "jewelry", examples: "แหวน สร้อย กำไล พลอย"),
    Category.new(key: "old_book", examples: "ฉบับพิมพ์เก่า แผนที่ เอกสาร"),
    Category.new(key: "painting", examples: "สีน้ำมัน สีน้ำ ภาพพิมพ์")
  ].freeze

  BIDDING_STEPS = [
    Step.new(title: "เลือกสินค้าที่สนใจ",
             body: "ดูรูป รายละเอียด และใบรับรอง ทุกชิ้นผ่านการตรวจสอบโดยทีมงานก่อนเปิดประมูล"),
    Step.new(title: "เสนอราคาครั้งเดียว",
             body: "ราคาต้องไม่ต่ำกว่าราคาเริ่มต้น ส่งแล้วแก้ไขไม่ได้ และไม่มีใครเห็นราคาของคุณ รวมทั้งผู้ขาย"),
    Step.new(title: "ปิดประมูล ประกาศผล",
             body: "ผู้เสนอสูงสุดชนะและจ่ายตามราคาที่เสนอ ถ้าราคาเท่ากัน ผู้ที่เสนอก่อนชนะ")
  ].freeze

  SELLING_STEPS = [
    Step.new(title: "ลงสินค้า", body: "ประเภท รายละเอียด รูป ราคาเริ่มต้น"),
    Step.new(title: "ทีมงานตรวจสอบ", body: "โดยทั่วไป 1–2 วันทำการ"),
    Step.new(title: "เปิดประมูล", body: "รับแจ้งผลทางอีเมลเมื่อปิดประมูล")
  ].freeze

  FAQS = [
    Faq.new(question: "แก้ไขหรือถอนราคาที่เสนอไปแล้วได้ไหม",
            answer: "ไม่ได้ครับ ในการประมูลแบบปิดผนึก แต่ละคนเสนอราคาได้ครั้งเดียว ระบบจะให้ยืนยันอีกครั้งก่อนส่ง จึงควรตรวจราคาให้แน่ใจ"),
    Faq.new(question: "ใครเห็นราคาที่ฉันเสนอบ้าง",
            answer: "ไม่มีใครเห็นราคาของคุณระหว่างประมูล ทั้งผู้เสนอคนอื่นและผู้ขาย ระบบแสดงเพียงจำนวนผู้เสนอราคา"),
    Faq.new(question: "ถ้ามีคนเสนอราคาเท่ากันจะเป็นอย่างไร",
            answer: "ผู้ที่เสนอราคานั้นก่อนเป็นผู้ชนะ"),
    Faq.new(question: "ชำระเงินและรับสินค้าอย่างไร",
            answer: "เมื่อปิดประมูล ผู้ชนะจะได้รับอีเมลแจ้งผลพร้อมขั้นตอนการชำระเงินและการจัดส่ง"),
    Faq.new(question: "มีค่าธรรมเนียมไหม",
            answer: "สมัครสมาชิกและลงขายสินค้าฟรีในช่วงทดลอง (Beta)")
  ].freeze

  attr_reader :now

  def initialize(now: Time.current)
    @now = now
  end

  def categories = CATEGORIES
  def bidding_steps = BIDDING_STEPS
  def selling_steps = SELLING_STEPS
  def faqs = FAQS

  def featured_auction = live_auctions.first

  # การ์ดเล็กใต้การ์ดหลักใน hero: รายการที่กำลังจะเริ่ม 1 ชิ้น + กำลังประมูลอีก 1 ชิ้น
  def hero_side_auctions = [ upcoming_auctions.first, live_auctions.second ]

  def live_auctions
    @live_auctions ||= [
      live("นาฬิกาพกโบราณ ปี 1920 ตัวเรือนเงิน", "watch", 4_500, 12, "นาฬิกาพก", 1.day + 4.hours + 12.minutes + 36.seconds),
      live("ภาพพิมพ์แกะไม้ ตลาดน้ำ ลงนามศิลปิน", "painting", 9_500, 7, "ภาพพิมพ์แกะไม้", 6.hours),
      live("แผนที่สยามพิมพ์หิน ค.ศ. 1900", "old_book", 6_400, 3, "แผนที่", 2.days),
      live("กำไลข้อมือนาก ลายดอกพิกุล", "jewelry", 15_000, 19, "กำไล", 45.minutes)
    ]
  end

  def upcoming_auctions
    @upcoming_auctions ||= [
      upcoming("แหวนพลอยไพลิน ตัวเรือนทอง", "jewelry", 8_000, "แหวนพลอย", 4.days + 20.hours),
      upcoming("นาฬิกาข้อมือไขลาน ปี 1965", "watch", 3_200, "นาฬิกาข้อมือ", 5.days + 19.hours),
      upcoming("ภาพสีน้ำ วัดอรุณยามเย็น", "painting", 5_000, "ภาพสีน้ำ", 6.days + 20.hours),
      upcoming("วารสารเก่า ชุด 12 เล่ม พ.ศ. 2500", "old_book", 1_500, "วารสาร", 7.days + 10.hours)
    ]
  end

  private

  def live(title, category, price, bidders, image_label, closes_in)
    Auction.new(title:, category:, starting_price: price, bidder_count: bidders, image_label:,
                starts_at: now - 1.day, ends_at: now + closes_in)
  end

  # เวลาเริ่มนับจากเที่ยงคืนของวันนี้ เพื่อให้ได้เวลาเริ่มเป็นชั่วโมงลงตัว (เช่น 20:00)
  def upcoming(title, category, price, image_label, starts_in)
    starts_at = now.beginning_of_day + starts_in
    Auction.new(title:, category:, starting_price: price, bidder_count: 0, image_label:,
                starts_at:, ends_at: starts_at + 3.days)
  end
end
