import { Controller } from "@hotwired/stimulus"

// input ไฟล์ถูกซ่อน (sr-only) แล้วให้ label เป็นปุ่ม — controller นี้บอกผู้ใช้ว่าเลือกไฟล์ไปแล้วกี่ไฟล์
export default class extends Controller {
  static targets = [ "input", "summary" ]

  show() {
    const files = Array.from(this.inputTarget.files)
    if (files.length === 0) {
      this.summaryTarget.textContent = ""
    } else if (files.length === 1) {
      this.summaryTarget.textContent = `เลือกแล้ว: ${files[0].name}`
    } else {
      this.summaryTarget.textContent = `เลือกแล้ว ${files.length} ไฟล์ — จะอัปโหลดเมื่อกดบันทึก`
    }
  }
}
