module ProductsHelper
  CATEGORY_LABELS = { "watch" => "นาฬิกา", "jewelry" => "เครื่องประดับ", "old_book" => "หนังสือเก่า", "painting" => "ภาพวาด" }.freeze

  STATUS_BADGES = {
    "draft" => [ "ฉบับร่าง", "○", "bg-muted-2 text-neutral-ink" ],
    "pending_review" => [ "รอตรวจสอบ", "◷", "bg-accent-soft text-accent-ink" ],
    "approved" => [ "อนุมัติแล้ว", "✓", "bg-success-soft text-success" ],
    "rejected" => [ "ไม่อนุมัติ", "!", "bg-danger-soft text-danger-ink" ]
  }.freeze

  # sm = ในตาราง, md = รายการ/การ์ด, lg = หัวหน้าตรวจสินค้า
  BADGE_SIZES = {
    sm: "px-2.5 py-0.5 text-xs",
    md: "px-3 py-1 text-[13px]",
    lg: "px-3.5 py-1 text-sm"
  }.freeze

  THAI_MONTHS = %w[ม.ค. ก.พ. มี.ค. เม.ย. พ.ค. มิ.ย. ก.ค. ส.ค. ก.ย. ต.ค. พ.ย. ธ.ค.].freeze

  DECISION_LABELS = { "approved" => "อนุมัติ", "rejected" => "ไม่อนุมัติ" }.freeze

  def category_label(category)
    CATEGORY_LABELS.fetch(category.to_s, category.to_s)
  end

  def category_options
    CATEGORY_LABELS.map { |value, label| [ label, value ] }
  end

  def status_badge(product, size: :md)
    label, icon, classes = STATUS_BADGES.fetch(product.status)
    tag.span(class: "inline-flex items-center gap-1.5 whitespace-nowrap rounded-full font-semibold #{BADGE_SIZES.fetch(size)} #{classes}") do
      safe_join([ tag.span(icon, aria: { hidden: true }), label ])
    end
  end

  ACTION_LABELS = {
    "draft" => "แก้ไขต่อ",
    "pending_review" => "ดูรายละเอียด",
    "approved" => "ดูรายละเอียด",
    "rejected" => "แก้ไขและส่งใหม่"
  }.freeze

  # แท็บกรองสถานะ: [ค่า param, ป้ายเต็ม, ป้ายสั้นบนมือถือ]
  STATUS_TABS = [
    [ "all", "ทั้งหมด", "ทั้งหมด" ],
    [ "draft", "ฉบับร่าง", "ฉบับร่าง" ],
    [ "pending_review", "รอตรวจสอบ", "รอตรวจ" ],
    [ "approved", "อนุมัติแล้ว", "อนุมัติ" ],
    [ "rejected", "ไม่อนุมัติ", "ไม่อนุมัติ" ]
  ].freeze

  REASON_PREVIEW_LENGTH = 40

  def product_action_label(product)
    ACTION_LABELS.fetch(product.status)
  end

  # บรรทัดรายละเอียดใต้ชื่อสินค้าในรายการ — เปลี่ยนตามสถานะ
  def product_meta(product)
    images = product.images.size
    photos = images.positive? ? "#{images} รูป" : "ยังไม่มีรูป"
    certificate = product.certificate.attached? ? " · มีใบรับรอง" : ""

    case product.status
    when "draft" then "แก้ไขล่าสุด #{thai_short_time(product.updated_at)} · #{photos}#{certificate}"
    when "pending_review" then "ส่งตรวจสอบ #{thai_short_time(product.submitted_at)} · #{photos}#{certificate}"
    when "approved" then approved_meta(product)
    when "rejected" then rejected_meta(product)
    end
  end

  CATEGORY_ICONS = {
    "watch" => '<circle cx="12" cy="12" r="5"/><path d="M12 9.5V12l1.5 1M9 7l.7-4h4.6L15 7M9 17l.7 4h4.6l.7-4"/>',
    "jewelry" => '<path d="M6 3h12l3 6-9 12L3 9l3-6Z"/><path d="M3 9h18M9 3l3 18M15 3l-3 18"/>',
    "old_book" => '<path d="M4 5a2 2 0 0 1 2-2h13v16H6a2 2 0 0 0-2 2V5Z"/><path d="M8 7h7"/>',
    "painting" => '<rect x="3" y="4" width="18" height="16" rx="2"/><circle cx="9" cy="10" r="1.5"/><path d="m21 16-5-5-8 8"/>'
  }.freeze

  # ไอคอนประเภทสินค้าบน radio tile (ตกแต่งอย่างเดียว ซ่อนจาก screen reader)
  def category_icon(category, size: 22)
    tag.svg(CATEGORY_ICONS.fetch(category.to_s).html_safe, aria: { hidden: true }, width: size, height: size,
            viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", "stroke-width": 1.8,
            "stroke-linecap": "round", "stroke-linejoin": "round")
  end

  # ข้อความ error ใต้ field — id ผูกกับ aria-describedby ของ input (`#{attribute}-errors`)
  def field_errors(record, attribute)
    messages = record.errors[attribute]
    return if messages.empty?

    tag.div(id: "#{attribute}-errors") do
      safe_join(messages.map { |message| tag.p("ข้อผิดพลาด: #{message}", class: "field-error", role: "alert") })
    end
  end

  def decision_label(review)
    DECISION_LABELS.fetch(review.decision)
  end

  def baht(amount)
    "฿#{number_with_delimiter(amount)}"
  end

  def duration_label(minutes)
    return "-" if minutes.blank?

    if (minutes % 1440).zero? then "#{minutes / 1440} วัน"
    elsif (minutes % 60).zero? then "#{minutes / 60} ชั่วโมง"
    else "#{minutes} นาที"
    end
  end

  def duration_options
    Product::DURATION_CHOICES.map { |minutes| [ duration_label(minutes), minutes ] }
  end

  def thai_time(time)
    time ? time.in_time_zone.strftime("%-d/%-m/%Y %H:%M") : "-"
  end

  # "8 พ.ย. 16:40" — ไม่แสดงปี ใช้ในตารางและรายการ
  def thai_short_time(time)
    return "-" unless time

    local = time.in_time_zone
    "#{local.day} #{THAI_MONTHS[local.month - 1]} #{local.strftime('%H:%M')}"
  end

  # "9 พ.ย. 2569 10:15" — ปี พ.ศ. ใช้ใน banner และ timeline
  def thai_date_be(time)
    return "-" unless time

    local = time.in_time_zone
    "#{local.day} #{THAI_MONTHS[local.month - 1]} #{local.year + 543} #{local.strftime('%H:%M')}"
  end

  # "ต.ค. 2569"
  def thai_month_year_be(time)
    return "-" unless time

    local = time.in_time_zone
    "#{THAI_MONTHS[local.month - 1]} #{local.year + 543}"
  end

  # เวลาที่รอนับจาก from: ต่ำกว่า 48 ชม. แสดงเป็นชั่วโมง ตั้งแต่ 48 ชม. แสดงเป็นวัน
  def waiting_time(from, now: Time.current)
    return "-" unless from

    hours = [ ((now - from) / 1.hour).floor, 0 ].max
    return "รอไม่ถึง 1 ชม." if hours < 1
    return "รอ #{hours} ชม." if hours < 48

    days, rest = hours.divmod(24)
    rest.zero? ? "รอ #{days} วัน" : "รอ #{days} วัน #{rest} ชม."
  end

  # รูปย่อ (ไม่สร้าง variant เพื่อไม่ต้องพึ่ง libvips ตอนแสดงผล)
  def product_thumb(image, alt:, class_name: "size-18")
    return tag.div("ไม่มีรูป", class: "#{class_name} flex shrink-0 items-center justify-center rounded-lg bg-muted text-xs text-ink-2") unless image

    image_tag(url_for(image), alt: alt, class: "#{class_name} shrink-0 rounded-lg object-cover bg-muted")
  end

  private

  # สินค้าที่อนุมัติโดยไม่มี review (เช่น ข้อมูลเก่า) ใช้เวลาแก้ไขล่าสุดแทน
  def approved_meta(product)
    approved_at = product.reviews.select(&:approved?).last&.created_at || product.updated_at
    "อนุมัติ #{thai_short_time(approved_at)} · รอ Admin จัดรอบประมูล"
  end

  def rejected_meta(product)
    review = product.latest_rejection
    meta = "ไม่อนุมัติ #{thai_short_time(review&.created_at || product.updated_at)}"
    return meta if review&.reason.blank?

    "#{meta} · #{truncate(review.reason.squish, length: REASON_PREVIEW_LENGTH + 1, omission: "…")}"
  end
end
