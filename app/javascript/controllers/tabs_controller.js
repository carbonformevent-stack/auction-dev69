import { Controller } from "@hotwired/stimulus"

// แท็บตามแบบ WAI-ARIA: คลิกหรือกดลูกศรซ้าย/ขวาเพื่อสลับ panel
export default class extends Controller {
  static targets = ["tab", "panel"]

  select(event) {
    this.show(this.tabTargets.indexOf(event.currentTarget))
  }

  navigate(event) {
    const step = { ArrowRight: 1, ArrowLeft: -1 }[event.key]
    if (!step) return

    event.preventDefault()
    const current = this.tabTargets.indexOf(event.currentTarget)
    const next = (current + step + this.tabTargets.length) % this.tabTargets.length
    this.show(next)
    this.tabTargets[next].focus()
  }

  show(index) {
    this.tabTargets.forEach((tab, i) => {
      tab.setAttribute("aria-selected", String(i === index))
      tab.tabIndex = i === index ? 0 : -1
    })
    this.panelTargets.forEach((panel, i) => { panel.hidden = i !== index })
  }
}
