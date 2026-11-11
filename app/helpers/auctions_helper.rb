module AuctionsHelper
  THAI_WEEKDAYS = %w[อา. จ. อ. พ. พฤ. ศ. ส.].freeze

  AUCTION_STATUS_BADGES = {
    "scheduled" => [ "กำหนดการ", "◷", "bg-accent-soft text-accent-ink" ],
    "running" => [ "กำลังประมูล", "●", "bg-primary-soft text-primary-ink" ],
    "closed" => [ "ปิดแล้ว", "■", "bg-muted-2 text-neutral-ink" ],
    "settled" => [ "ส่งมอบแล้ว", "✓", "bg-success-soft text-success" ],
    "cancelled" => [ "ยกเลิกแล้ว", "×", "bg-danger-soft text-danger-ink" ]
  }.freeze

  # [ค่า enum, ป้าย, เปิดใช้ได้หรือยัง] — วิธีอื่นมาใน M6
  AUCTION_TYPE_OPTIONS = [
    [ "fpsba", "FPSBA — ประมูลแบบปิดผนึก ราคาสูงสุดชนะ", true ],
    [ "english", "English — ประมูลแบบเปิด (เร็ว ๆ นี้)", false ],
    [ "vickrey", "Vickrey — ปิดผนึก จ่ายราคาอันดับ 2 (เร็ว ๆ นี้)", false ],
    [ "dutch", "Dutch — ราคาลดลงตามเวลา (เร็ว ๆ นี้)", false ]
  ].freeze

  AUCTION_TYPE_HINTS = {
    "fpsba" => "ผู้ประมูลเสนอราคาได้คนละ 1 ครั้ง ซ่อนราคาทุกคนจนปิดประมูล ราคาเท่ากันผู้เสนอก่อนชนะ"
  }.freeze

  def auction_status_badge(auction, size: :md)
    label, icon, classes = AUCTION_STATUS_BADGES.fetch(auction.status)
    tag.span(class: "inline-flex items-center gap-1.5 whitespace-nowrap rounded-full font-semibold #{ProductsHelper::BADGE_SIZES.fetch(size)} #{classes}") do
      safe_join([ tag.span(icon, aria: { hidden: true }), label ])
    end
  end

  def auction_type_label(auction)
    auction.auction_type.upcase
  end

  def auction_type_options(selected)
    safe_join(AUCTION_TYPE_OPTIONS.map do |value, label, enabled|
      tag.option(label, value: value, selected: value == selected, disabled: !enabled)
    end)
  end

  # "ส. 15 พ.ย. 2569 20:00 น." — วันเวลาเปิด/ปิดประมูล
  def thai_datetime_full(time)
    return "—" unless time

    local = time.in_time_zone
    "#{THAI_WEEKDAYS[local.wday]} #{local.day} #{ProductsHelper::THAI_MONTHS[local.month - 1]} " \
      "#{local.year + 543} #{local.strftime('%H:%M')} น."
  end
end
