import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["file", "button"]

  async upload(event) {
    event.preventDefault()

    if (!this.fileTarget.files[0]) {
      alert("Seleziona un file .txt")
      return
    }

    this.buttonTarget.disabled = true
    this.buttonTarget.textContent = "Uploading..."

    const formData = new FormData()
    formData.append("generation_file", this.fileTarget.files[0])

    const token = document.querySelector('meta[name="csrf-token"]').content

    try {
      const response = await fetch("/api/simulations", {
        method: "POST",
        headers: {
          "X-CSRF-Token": token,
          "Accept": "application/json"
        },
        body: formData
      })

      if (!response.ok) {
        const text = await response.text()
        console.error("Upload failed", response.status, text)
        alert(`Error ${response.status}: ${text}`)
        this.resetButton()
        return
      }

      const data = await response.json()
      window.location = `/simulations/${data.id}`
    } catch (error) {
      console.error(error)
      alert("Network error during upload")
      this.resetButton()
    }
  }

  resetButton() {
    this.buttonTarget.disabled = false
    this.buttonTarget.textContent = "Upload"
  }
}