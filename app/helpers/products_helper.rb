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
end
