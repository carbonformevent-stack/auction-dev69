import { Controller } from "@hotwired/stimulus"

// dialog "ไม่อนุมัติสินค้านี้": เหตุผลสำเร็จรูปเติมต่อท้าย, ตัวนับ, และปุ่มยืนยันถูกปิดจนเหตุผลครบขั้นต่ำ
// กติกาจริงอยู่ที่ ProductReview (server) — ฝั่งนี้แค่ช่วยให้รู้ตัวก่อนกดส่ง
export default class extends Controller {
  static targets = [ "dialog", "reason", "counter", "submit" ]
  static values = { open: Boolean, min: { type: Number, default: 10 } }

  connect() {
    this.update()
    // server ตอบ 422 กลับมาเพราะเหตุผลสั้นไป — เปิด dialog ค้างไว้ให้แก้ต่อ
    if (this.openValue && !this.dialogTarget.open) this.open()
  }

  open() {
    this.dialogTarget.showModal()
    this.reasonTarget.focus()
  }

  close() {
    this.dialogTarget.close()
  }

  // คลิกบริเวณ backdrop (ตัว dialog เอง ไม่ใช่เนื้อใน) = ปิด
  backdrop(event) {
    if (event.target === this.dialogTarget) this.close()
  }

  preset(event) {
    const current = this.reasonTarget.value.trimEnd()
    this.reasonTarget.value = current ? `${current}\n${event.params.text}` : event.params.text
    this.update()
    this.reasonTarget.focus()
  }

  update() {
    const length = this.reasonTarget.value.trim().length
    const enough = length >= this.minValue

    this.submitTarget.disabled = !enough
    this.counterTarget.textContent = enough
      ? `${length} ตัวอักษร`
      : `ต้องกรอกเหตุผลอย่างน้อย ${this.minValue} ตัวอักษร (ตอนนี้ ${length})`
    this.counterTarget.classList.toggle("text-danger", !enough)
    this.counterTarget.classList.toggle("text-ink-2", enough)
  }
}
