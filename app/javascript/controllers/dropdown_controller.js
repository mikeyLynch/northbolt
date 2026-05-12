import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "chevron"]

  toggle() {
    const open = this.menuTarget.classList.toggle("hidden")
    this.chevronTarget.classList.toggle("rotate-180", !open)
  }

  close(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.add("hidden")
      this.chevronTarget.classList.remove("rotate-180")
    }
  }
}
