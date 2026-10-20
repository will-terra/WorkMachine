import { Controller } from "@hotwired/stimulus"

// Refreshes the page (morphing, scroll kept) when you come back to this tab, so the triage
// list reflects what was saved or discarded in the posting tabs that closed themselves.
export default class extends Controller {
  connect() {
    this.onVisibilityChange = () => {
      if (document.hidden) {
        this.leftAt = Date.now()
      } else if (this.leftAt) {
        this.leftAt = null
        Turbo.visit(window.location.href, { action: "replace" })
      }
    }
    document.addEventListener("visibilitychange", this.onVisibilityChange)
  }

  disconnect() {
    document.removeEventListener("visibilitychange", this.onVisibilityChange)
  }
}
