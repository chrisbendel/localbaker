import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["addressInput"]

  requestLocation(event) {
    event.preventDefault()

    if (!navigator.geolocation) {
      alert("Geolocation is not supported by your browser. Please enter your address manually.")
      return
    }

    // Show loading state
    const button = event.target
    const originalText = button.textContent
    button.textContent = "📍 Getting location..."
    button.disabled = true

    navigator.geolocation.getCurrentPosition(
      (position) => {
        const { latitude, longitude } = position.coords
        this.submitWithCoordinates(latitude, longitude, button, originalText)
      },
      (error) => {
        console.error("Geolocation error:", error)
        alert("Unable to get your location. Please enter your address manually.")
        button.textContent = originalText
        button.disabled = false
      }
    )
  }

  submitWithCoordinates(latitude, longitude, button, originalText) {
    // Store coordinates in hidden inputs
    const form = button.closest("form")

    let latInput = form.querySelector('input[name="latitude"]')
    let lngInput = form.querySelector('input[name="longitude"]')

    if (!latInput) {
      latInput = document.createElement("input")
      latInput.type = "hidden"
      latInput.name = "latitude"
      form.appendChild(latInput)
    }

    if (!lngInput) {
      lngInput = document.createElement("input")
      lngInput.type = "hidden"
      lngInput.name = "longitude"
      form.appendChild(lngInput)
    }

    latInput.value = latitude
    lngInput.value = longitude

    // Submit the form
    form.submit()
  }
}
