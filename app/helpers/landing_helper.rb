module LandingHelper
  THAI_WEEKDAYS = %w[อา. จ. อ. พ. พฤ. ศ. ส.].freeze

  # ป้ายเวลาที่เหลือบนการ์ด: "45 นาที", "6 ชม.", "1 วัน 04:12", "2 วัน"
  def time_left_label(ends_at, now: Time.current)
    seconds = [ (ends_at - now).to_i, 0 ].max
    return "#{[ seconds / 60, 1 ].max} นาที" if seconds < 1.hour
    return "#{seconds / 1.hour} ชม." if seconds < 1.day

    days, rest = seconds.divmod(1.day)
    return "#{days} วัน" if days >= 2

    hours, rest = rest.divmod(1.hour)
    format("%d วัน %02d:%02d", days, hours, rest / 1.minute)
  end

  # ตัวนับถอยหลังแบบมีวินาที "1 วัน 04:12:36" — ตรงกับรูปแบบใน countdown_controller.js
  def countdown_text(ends_at, now: Time.current)
    seconds = [ (ends_at - now).to_i, 0 ].max
    days, rest = seconds.divmod(1.day)
    hours, rest = rest.divmod(1.hour)
    clock = format("%02d:%02d:%02d", hours, rest / 1.minute, rest % 1.minute)
    days.positive? ? "#{days} วัน #{clock}" : clock
  end

  # "ส. 15 พ.ย. 20:00"
  def thai_weekday_time(time)
    local = time.in_time_zone
    "#{THAI_WEEKDAYS[local.wday]} #{local.day} #{ProductsHelper::THAI_MONTHS[local.month - 1]} #{local.strftime('%H:%M')}"
  end

  # ป้ายมุมซ้ายบนของการ์ดประมูล
  def auction_badge(auction, now: Time.current)
    if auction.live?(now)
      text = "ปิดใน #{time_left_label(auction.ends_at, now:)}"
      classes = auction.closing_soon?(now) ? "bg-accent text-accent-ink" : "bg-surface text-ink"
    else
      text = "เริ่ม #{thai_weekday_time(auction.starts_at)}"
      classes = "bg-surface text-ink"
    end
    tag.span(text, class: "absolute left-3 top-3 rounded-full px-2.5 py-0.5 text-xs font-semibold shadow-sm #{classes}")
  end

  # กรอบรูปสินค้าตัวอย่าง (ยังไม่มีรูปจริง)
  def image_placeholder(label, class_name: "aspect-[4/3]")
    tag.div("[รูป: #{label}]", class: "flex items-center justify-center bg-muted-2 text-sm text-ink-2 #{class_name}")
  end
end
