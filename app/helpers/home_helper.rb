module HomeHelper
  # ตัวอย่างสินค้าใต้ชื่อหมวดบนหน้าแรก
  CATEGORY_EXAMPLES = {
    "watch" => "นาฬิกาพก ข้อมือ ตั้งโต๊ะ",
    "jewelry" => "แหวน สร้อย กำไล พลอย",
    "old_book" => "ฉบับพิมพ์เก่า แผนที่ เอกสาร",
    "painting" => "สีน้ำมัน สีน้ำ ภาพพิมพ์"
  }.freeze

  def category_examples(category)
    CATEGORY_EXAMPLES.fetch(category.to_s, "")
  end

  # วงกลมตัวเลขลำดับขั้นตอน
  def step_number(number, class_name: "size-9 bg-primary text-on-primary")
    tag.span(number, aria: { hidden: true }, class: "flex shrink-0 items-center justify-center rounded-full font-bold #{class_name}")
  end
end
