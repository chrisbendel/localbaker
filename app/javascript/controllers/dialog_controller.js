import { Controller } from "@hotwired/stimulus"

// Generic modal dialog: a trigger calls #open, the native <dialog> handles
// Esc-to-close, and tapping the backdrop closes too. Used for confirm-with-input
// flows that a plain turbo_confirm can't cover (e.g. event cancellation reason).
export default class extends Controller {
  static targets = ["dialog"]

  // Close before Turbo snapshots, or back-navigation restores a stuck-open modal.
  disconnect() {
    if (this.hasDialogTarget) this.dialogTarget.close()
  }

  open() {
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }

  backdropClose(event) {
    if (event.target === this.dialogTarget) this.close()
  }
}
