import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "clear"]

  connect() {
    this.#updateClear()
  }

  input() {
    clearTimeout(this._debounce)
    this._debounce = setTimeout(() => this.element.requestSubmit(), 300)
    this.#updateClear()
  }

  clear() {
    this.inputTarget.value = ""
    this.element.requestSubmit()
    this.#updateClear()
  }

  #updateClear() {
    this.clearTarget.classList.toggle("hidden", this.inputTarget.value === "")
  }
}
