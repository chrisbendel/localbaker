import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  copy() {
    navigator.clipboard.writeText(this.urlValue).then(() => {
      this.showToast("Store link copied")
      const btn = this.element.querySelector(".copy-btn")
      btn.classList.add("copied")
      setTimeout(() => btn.classList.remove("copied"), 2000)
    })
  }

  showToast(message) {
    const toast = document.createElement("p")
    toast.className = "copy-toast"
    toast.textContent = message
    document.body.appendChild(toast)
    setTimeout(() => toast.remove(), 2500)
  }
}
