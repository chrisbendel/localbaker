import { Controller } from "@hotwired/stimulus"

// Single-dialog lightbox for the storefront photo strip.
// One <dialog> shared by all photos: arrow keys + buttons navigate,
// horizontal swipe navigates on touch, Esc closes natively,
// tapping the backdrop closes.
export default class extends Controller {
  static targets = ["dialog", "image", "thumb"]

  // Close before Turbo snapshots the page, or back-navigation restores a
  // stuck-open modal from the cache.
  disconnect() {
    if (this.hasDialogTarget) this.dialogTarget.close()
  }

  open(event) {
    this.index = event.params.index
    this.show()
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }

  next() {
    this.step(1)
  }

  prev() {
    this.step(-1)
  }

  keydown(event) {
    if (event.key === "ArrowRight") this.next()
    if (event.key === "ArrowLeft") this.prev()
  }

  touchStart(event) {
    this.startX = event.changedTouches[0].clientX
  }

  touchEnd(event) {
    const dx = event.changedTouches[0].clientX - this.startX
    if (Math.abs(dx) > 40) dx < 0 ? this.next() : this.prev()
  }

  backdropClose(event) {
    if (event.target === this.dialogTarget) this.close()
  }

  step(delta) {
    const count = this.thumbTargets.length
    this.index = (this.index + delta + count) % count
    this.show()
  }

  show() {
    this.imageTarget.src = this.thumbTargets[this.index].dataset.full
  }
}
