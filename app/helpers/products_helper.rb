module ProductsHelper
  CATEGORY_LABELS = { "watch" => "นาฬิกา", "jewelry" => "เครื่องประดับ", "old_book" => "หนังสือเก่า", "painting" => "ภาพวาด" }.freeze

  STATUS_BADGES = {
    "draft" => [ "ร่าง", "○", "bg-muted-2 text-neutral-ink" ],
    "pending_review" => [ "รอตรวจ", "◷", "bg-accent-soft text-accent-ink" ],
    "approved" => [ "อนุมัติแล้ว", "✓", "bg-success-soft text-success" ],
    "rejected" => [ "ไม่อนุมัติ", "!", "bg-danger-soft text-danger-ink" ]
  }.freeze

  DECISION_LABELS = { "approved" => "อนุมัติ", "rejected" => "ไม่อนุมัติ" }.freeze

  def category_label(category)
    CATEGORY_LABELS.fetch(category.to_s, category.to_s)
  end

  def category_options
    CATEGORY_LABELS.map { |value, label| [ label, value ] }
  end

  def status_badge(product)
    label, icon, classes = STATUS_BADGES.fetch(product.status)
    tag.span(class: "inline-flex items-center gap-1.5 whitespace-nowrap rounded-full px-3 py-1 text-[13px] font-semibold #{classes}") do
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

  # รูปย่อ (ไม่สร้าง variant เพื่อไม่ต้องพึ่ง libvips ตอนแสดงผล)
  def product_thumb(image, alt:, class_name: "size-18")
    return tag.div("ไม่มีรูป", class: "#{class_name} flex shrink-0 items-center justify-center rounded-lg bg-muted text-xs text-ink-2") unless image

    image_tag(url_for(image), alt: alt, class: "#{class_name} shrink-0 rounded-lg object-cover bg-muted")
  end
end
