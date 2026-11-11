# ความพร้อมของสินค้าก่อนส่งตรวจ แยกเป็น 5 ขั้นตามหน้าฟอร์มลงสินค้า
# ใช้ร่วมกันใน step bar, สรุปด้านข้าง (desktop) และแถบความคืบหน้า (มือถือ)
# เป็นแค่ "ตัวช่วยแสดงผล" — กติกาจริงอยู่ที่ validation ของ Product
module Products
  class Readiness
    Step = Struct.new(:key, :label, :status)

    STEP_LABELS = {
      category: "ประเภท",
      details: "รายละเอียด",
      images: "รูปภาพ",
      certificate: "ใบรับรอง",
      price_and_time: "ราคาและเวลา"
    }.freeze

    def initialize(product)
      @product = product
    end

    def steps
      @steps ||= STEP_LABELS.map { |key, label| Step.new(key, label, status_for(key)) }
    end

    def total = steps.size

    def done_count = steps.count { |step| step.status == :done }

    # ใบรับรองไม่บังคับ จึงไม่ถูกนับว่าขวางการส่ง
    def ready_to_submit? = steps.none? { |step| step.status == :todo }

    # ขั้นแรกที่ยังไม่เสร็จ (nil = เสร็จทุกขั้น)
    def current_step = steps.find { |step| step.status != :done }&.key

    private

    def status_for(key)
      return (certificate_attached? ? :done : :optional) if key == :certificate

      done?(key) ? :done : :todo
    end

    def done?(key)
      case key
      when :category then @product.category.present?
      when :details then @product.title.present? && @product.description.present?
      when :images then @product.images.size.positive?
      when :price_and_time then valid_price? && valid_duration?
      end
    end

    def certificate_attached? = @product.certificate.attached?

    def valid_price? = Product::PRICE_RANGE.cover?(@product.starting_price)

    def valid_duration? = Product::DURATION_RANGE.cover?(@product.desired_duration_minutes)
  end
end
