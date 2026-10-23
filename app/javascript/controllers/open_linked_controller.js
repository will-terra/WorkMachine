import { Controller } from "@hotwired/stimulus"

// A link to a folded section (#google, #linkedin_alerts from the notice on top or from the
// Rotina) opens it, on load and on links within the page.
export default class extends Controller {
  connect() {
    this.open()
  }

  open() {
    const target = document.getElementById(decodeURIComponent(window.location.hash.slice(1)))
    const details = target?.closest("details")
    if (!details || details.open) return

    details.open = true
    target.scrollIntoView()
  }
}
