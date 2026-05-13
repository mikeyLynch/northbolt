import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["existingFields", "newFields", "modeInput"]

  connect() {
    this.showExisting()
  }

  showExisting() {
    this.modeInputTarget.value = "existing"
    this.existingFieldsTarget.classList.remove("hidden")
    this.newFieldsTarget.classList.add("hidden")
  }

  showNew() {
    this.modeInputTarget.value = "new"
    this.existingFieldsTarget.classList.add("hidden")
    this.newFieldsTarget.classList.remove("hidden")
  }
}
