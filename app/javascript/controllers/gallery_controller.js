import { Controller } from "@hotwired/stimulus"

// แกลเลอรีรูปสินค้า: คลิกรูปย่อเพื่อสลับรูปใหญ่
// ไม่มี JS ก็ยังใช้ได้ — รูปย่อเป็นลิงก์ไปไฟล์เต็ม
export default class extends Controller {
  static targets = [ "main", "counter", "full", "thumb" ]

  select(event) {
    event.preventDefault()
    const thumb = event.currentTarget
    const index = this.thumbTargets.indexOf(thumb)

    this.mainTarget.src = thumb.href
    this.mainTarget.alt = thumb.dataset.alt
    if (this.hasFullTarget) this.fullTarget.href = thumb.href
    if (this.hasCounterTarget) this.counterTarget.textContent = `${index + 1} / ${this.thumbTargets.length}`

    this.thumbTargets.forEach((el) => {
      if (el === thumb) el.setAttribute("aria-current", "true")
      else el.removeAttribute("aria-current")
    })
  }
}
