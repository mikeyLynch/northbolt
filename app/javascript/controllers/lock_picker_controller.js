import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["rows", "template"]
  static values  = { locks: Array }

  addRow() {
    const index = Date.now()
    const html  = this.templateTarget.innerHTML.replace(/INDEX/g, index)
    this.rowsTarget.insertAdjacentHTML("beforeend", html)
  }

  removeRow(event) {
    event.currentTarget.closest("[data-lock-picker-row]").remove()
  }

  filter(event) {
    const input    = event.currentTarget
    const query    = input.value.trim().toLowerCase()
    const row      = input.closest("[data-lock-picker-row]")
    const dropdown = row.querySelector("[data-lock-dropdown]")

    if (!query) {
      dropdown.classList.add("hidden")
      return
    }

    const matches = this.locksValue
      .filter(l =>
        l.unit_identifier.toLowerCase().includes(query) ||
        l.location_name.toLowerCase().includes(query)
      )
      .slice(0, 8)

    if (matches.length === 0) {
      dropdown.innerHTML = `<div class="px-3 py-2 text-sm text-gray-400">No locks found</div>`
    } else {
      dropdown.innerHTML = matches.map(l => `
        <button type="button"
                class="w-full text-left px-3 py-2 text-sm hover:bg-gray-50 flex items-center justify-between gap-4"
                data-action="click->lock-picker#select"
                data-id="${l.id}"
                data-label="Unit ${l.unit_identifier} — ${l.location_name}">
          <span class="font-medium text-gray-900">Unit ${l.unit_identifier}</span>
          <span class="text-gray-400 text-xs shrink-0">${l.location_name}</span>
        </button>
      `).join("")
    }

    dropdown.classList.remove("hidden")
  }

  select(event) {
    const btn      = event.currentTarget
    const row      = btn.closest("[data-lock-picker-row]")
    const dropdown = row.querySelector("[data-lock-dropdown]")

    row.querySelector("[data-lock-id-input]").value = btn.dataset.id
    row.querySelector("[data-lock-search]").value   = btn.dataset.label
    dropdown.classList.add("hidden")
  }

  closeDropdowns(event) {
    if (!this.element.contains(event.target)) {
      this.element.querySelectorAll("[data-lock-dropdown]").forEach(d => d.classList.add("hidden"))
    }
  }

  connect() {
    this._outsideClick = this.closeDropdowns.bind(this)
    document.addEventListener("click", this._outsideClick)
  }

  disconnect() {
    document.removeEventListener("click", this._outsideClick)
  }
}
