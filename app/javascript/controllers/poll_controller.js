import { Controller } from "@hotwired/stimulus"

// Reloads the surrounding Turbo Frame from `url` while an AI result is being generated.
// The finished result renders without this controller, so polling stops by itself.
export default class extends Controller {
  static values = { url: String, interval: { type: Number, default: 2000 } }

  connect() {
    this.timer = setInterval(() => this.refresh(), this.intervalValue)
  }

  refresh() {
    const frame = this.element.closest("turbo-frame")
    if (!frame) return
    if (frame.getAttribute("src") === this.urlValue) {
      frame.reload()
    } else {
      frame.src = this.urlValue
    }
  }

  disconnect() {
    clearInterval(this.timer)
  }
}
