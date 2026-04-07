import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["addressInput", "locationButton", "latitude", "longitude", "form"]

  requestLocation(event) {
    event.preventDefault()

    if (!navigator.geolocation) {
      alert("Geolocation is not supported by your browser. Please enter your address manually.")
      return
    }

    // Show loading state
    const originalText = this.locationButtonTarget.textContent
    this.locationButtonTarget.textContent = "Getting location..."
    this.locationButtonTarget.disabled = true

    navigator.geolocation.getCurrentPosition(
      (position) => {
        const { latitude, longitude } = position.coords
        this.submitWithCoordinates(latitude, longitude)
      },
      (error) => {
        console.error("Geolocation error:", error)
        alert("Unable to get your location. Please enter your address manually.")
        this.locationButtonTarget.textContent = originalText
        this.locationButtonTarget.disabled = false
      }
    )
  }

  submitWithCoordinates(latitude, longitude) {
    this.latitudeTarget.value = latitude
    this.longitudeTarget.value = longitude
    
    // Clear the address input so we don't accidentally prioritize it
    this.addressInputTarget.value = ""

    // Submit the form
    this.formTarget.submit()
  }
}
