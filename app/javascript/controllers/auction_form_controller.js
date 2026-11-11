import { Controller } from "@hotwired/stimulus"

// ฟอร์มสร้างการประมูล: แสดงเวลาเปิดรับราคา / ปิดประมูล และระยะเวลาในสรุปทันทีที่เปลี่ยนค่า
// เวลาที่กรอกเป็นเวลาประเทศไทย (UTC+7 ไม่มี daylight saving) — คำนวณเองไม่พึ่ง timezone ของเครื่องผู้ใช้
// server ตรวจซ้ำทุกครั้ง (Auction validation) ส่วนนี้แค่ช่วยให้เห็นผลก่อนกดสร้าง
const BANGKOK_OFFSET_MS = 7 * 60 * 60 * 1000
const WEEKDAYS = ["อา.", "จ.", "อ.", "พ.", "พฤ.", "ศ.", "ส."]
const MONTHS = ["ม.ค.", "ก.พ.", "มี.ค.", "เม.ย.", "พ.ค.", "มิ.ย.", "ก.ค.", "ส.ค.", "ก.ย.", "ต.ค.", "พ.ย.", "ธ.ค."]

export default class extends Controller {
  static targets = ["date", "time", "duration", "startText", "endText", "durationText", "pastError"]

  connect() {
    this.update()
  }

  update() {
    const start = this.startEpoch()
    const selected = this.durationTargets.find((input) => input.checked)
    const minutes = selected ? Number(selected.value) : NaN

    this.startTextTarget.textContent = this.format(start)
    this.endTextTarget.textContent = this.format(start + minutes * 60 * 1000)
    if (selected) this.durationTextTarget.textContent = selected.dataset.label
    this.pastErrorTarget.hidden = !(start <= Date.now())
  }

  // epoch (ms) ของวันที่+เวลาที่กรอก ตีความเป็นเวลาไทย; กรอกไม่ครบ = NaN
  startEpoch() {
    const [year, month, day] = this.dateTarget.value.split("-").map(Number)
    const [hour, minute] = this.timeTarget.value.split(":").map(Number)
    if ([year, month, day, hour, minute].some(Number.isNaN)) return NaN

    return Date.UTC(year, month - 1, day, hour, minute) - BANGKOK_OFFSET_MS
  }

  // "ส. 15 พ.ย. 2569 20:00 น." — ต้องตรงกับ AuctionsHelper#thai_datetime_full
  format(epoch) {
    if (Number.isNaN(epoch)) return "—"

    const local = new Date(epoch + BANGKOK_OFFSET_MS)
    const pad = (n) => String(n).padStart(2, "0")
    return `${WEEKDAYS[local.getUTCDay()]} ${local.getUTCDate()} ${MONTHS[local.getUTCMonth()]} ` +
      `${local.getUTCFullYear() + 543} ${pad(local.getUTCHours())}:${pad(local.getUTCMinutes())} น.`
  }
}
