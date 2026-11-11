import { Controller } from "@hotwired/stimulus"

// ตัวนับตัวอักษร "n/max" — max อ่านจาก maxlength ของ input
// ครบ max แล้วขึ้นข้อความ "ครบแล้ว" สีแดง (ค่าเริ่มต้นถูก render จาก server แล้ว)
export default class extends Controller {
  static targets = [ "input", "count" ]

  connect() {
    this.update()
  }

  update() {
    const max = this.inputTarget.maxLength
    const length = this.inputTarget.value.length
    const full = max > 0 && length >= max
    const format = (n) => n.toLocaleString("en-US")

    this.countTarget.textContent = `${format(length)}/${format(max)}${full ? " ครบแล้ว" : ""}`
    this.countTarget.classList.toggle("text-danger", full)
    this.countTarget.classList.toggle("font-semibold", full)
    this.countTarget.classList.toggle("text-ink-2", !full)
  }
}
