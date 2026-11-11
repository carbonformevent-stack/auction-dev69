import { Controller } from "@hotwired/stimulus"

// นับถอยหลังถึง endsAt ทุกวินาที — รูปแบบเดียวกับ LandingHelper#countdown_text ("1 วัน 04:12:36")
export default class extends Controller {
  static values = { endsAt: String }

  connect() {
    this.endsAt = Date.parse(this.endsAtValue)
    this.tick()
    this.timer = setInterval(() => this.tick(), 1000)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  tick() {
    const total = Math.max(0, Math.floor((this.endsAt - Date.now()) / 1000))
    const days = Math.floor(total / 86400)
    const pad = (n) => String(n).padStart(2, "0")
    const clock = `${pad(Math.floor((total % 86400) / 3600))}:${pad(Math.floor((total % 3600) / 60))}:${pad(total % 60)}`

    this.element.textContent = days > 0 ? `${days} วัน ${clock}` : clock
    if (total === 0) clearInterval(this.timer)
  }
}
