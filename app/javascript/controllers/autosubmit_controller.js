import { Controller } from "@hotwired/stimulus"

// Submits the surrounding form as soon as an input changes.
// Usage: form gets data-controller="autosubmit", input gets
// data-action="change->autosubmit#submit".
export default class extends Controller {
  submit() {
    this.element.requestSubmit()
  }
}
