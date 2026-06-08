import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { duration: { type: Number, default: 4000 } }

  connect() {
    this.timeout = setTimeout(() => this.dismiss(), this.durationValue)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  dismiss() {
    this.element.style.transition = "opacity 300ms ease, transform 300ms ease"
    this.element.style.opacity = "0"
    this.element.style.transform = "translateY(-4px)"
    setTimeout(() => this.element.remove(), 300)
  }
}
