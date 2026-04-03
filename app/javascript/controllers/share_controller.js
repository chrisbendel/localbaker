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
    const d = document.getElementById("flash-dialog")
    d.innerHTML = `<p>${message}</p>`
    d.show()
    setTimeout(() => d.close(), 3000)
  }
}
