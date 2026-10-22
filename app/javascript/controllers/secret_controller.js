import { Controller } from "@hotwired/stimulus"

// Shows only the start of a secret (the extension token) until "Mostrar" is clicked.
export default class extends Controller {
  static targets = ["text", "toggle"]

  toggle() {
    const shown = this.textTarget.dataset.shown === "true"
    const value = this.textTarget.dataset.secretValueValue
    this.textTarget.textContent = shown ? `${value.slice(0, 6)}${"•".repeat(20)}` : value
    this.textTarget.dataset.shown = String(!shown)
    this.toggleTarget.textContent = shown ? "Mostrar" : "Esconder"
  }
}
