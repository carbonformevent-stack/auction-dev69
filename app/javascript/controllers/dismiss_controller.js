import { Controller } from "@hotwired/stimulus"

// ปุ่ม × ของ toast — ลบ element ทิ้ง ไม่เก็บสถานะ
export default class extends Controller {
  close() {
    this.element.remove()
  }
}
