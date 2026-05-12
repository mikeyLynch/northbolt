import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["drawer", "backdrop", "badge"]
  static values = { url: String, unreadCountUrl: String }

  connect() {
    this.poll()
    this.interval = setInterval(() => this.poll(), 30000)
  }

  disconnect() {
    clearInterval(this.interval)
  }

  toggle() {
    const isOpen = !this.drawerTarget.classList.contains("translate-x-full")
    isOpen ? this.close() : this.open()
  }

  open() {
    const frame = this.drawerTarget.querySelector("turbo-frame")
    if (frame) frame.reload()
    this.drawerTarget.classList.remove("translate-x-full")
    this.backdropTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
  }

  close() {
    this.drawerTarget.classList.add("translate-x-full")
    this.backdropTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
  }

  async poll() {
    try {
      const response = await fetch(this.unreadCountUrlValue, {
        headers: { "Accept": "application/json" }
      })
      const { count } = await response.json()
      this.badgeTarget.classList.toggle("hidden", count === 0)
    } catch {
      // silently ignore poll failures
    }
  }
}
