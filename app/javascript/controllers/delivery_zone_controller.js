import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["zoneType", "radiusFields", "postalFields"]

  connect() {
    this.toggle()
  }

  toggle() {
    const type = this.zoneTypeTarget.value
    this.radiusFieldsTarget.hidden = type !== "radius"
    this.postalFieldsTarget.hidden = type !== "postal_codes"
  }
}
