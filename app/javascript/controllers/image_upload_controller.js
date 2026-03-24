import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "cancelButton"]

  connect() {
    this.toggleCancelButton()
  }

  changed() {
    this.toggleCancelButton()
  }

  cancel(e) {
    if (e) e.preventDefault()
    this.inputTarget.value = ""
    this.toggleCancelButton()
  }

  toggleCancelButton() {
    if (this.hasCancelButtonTarget) {
      if (this.inputTarget.files && this.inputTarget.files.length > 0) {
        this.cancelButtonTarget.style.display = "inline-block"
      } else {
        this.cancelButtonTarget.style.display = "none"
      }
    }
  }
}
