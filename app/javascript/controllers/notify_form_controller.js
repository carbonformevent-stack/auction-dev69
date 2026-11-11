import { Controller } from "@hotwired/stimulus"

// ฟอร์มรับแจ้งเตือนบนหน้าแรก — ยังไม่มีระบบเก็บอีเมล จึงไม่ส่งข้อมูลออกไป แค่ตรวจรูปแบบและแจ้งสถานะ
export default class extends Controller {
  static targets = ["email", "message"]

  submit(event) {
    event.preventDefault()

    if (!this.emailTarget.checkValidity() || this.emailTarget.value.trim() === "") {
      this.emailTarget.setAttribute("aria-invalid", "true")
      this.messageTarget.textContent = "กรุณากรอกอีเมลให้ถูกต้อง"
      return
    }

    this.emailTarget.removeAttribute("aria-invalid")
    this.messageTarget.textContent = "ขอบคุณที่สนใจ — ระบบแจ้งเตือนทางอีเมลจะเปิดให้ลงทะเบียนเร็ว ๆ นี้"
  }
}
