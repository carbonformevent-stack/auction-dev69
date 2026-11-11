module ApplicationHelper
  # สระหน้าอักษร (เ แ โ ใ ไ) ไม่เหมาะเป็นอักษรย่อใน avatar
  THAI_LEADING_VOWELS = "เแโใไ".freeze

  # อยู่ใน namespace admin หรือไม่ — ใช้เลือก header และเมนู
  def admin_area?
    controller_path.start_with?("admin/")
  end

  # อักษรแรกของชื่อ (หรืออีเมลถ้าไม่มีชื่อ) สำหรับ avatar
  def avatar_initial(user)
    name = user.display_name.to_s.sub(/\A[\s#{THAI_LEADING_VOWELS}]+/, "")
    name.first.to_s.upcase.presence || "?"
  end

  def nav_link_classes(current: false)
    base = "flex min-h-11 items-center rounded-lg px-3 no-underline"
    current ? "#{base} bg-primary-soft font-semibold text-primary-ink" : "#{base} text-ink hover:bg-muted"
  end
end
