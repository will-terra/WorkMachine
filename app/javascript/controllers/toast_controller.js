import { Controller } from "@hotwired/stimulus"

// A toast at the bottom left. With a delay it goes away by itself, except while the pointer is
// over it (time to reach "Desfazer").
export default class extends Controller {
  static values = { delay: Number }

  connect() {
    this.start()
    this.element.addEventListener("mouseenter", this.stop)
    this.element.addEventListener("mouseleave", this.start)
  }

  disconnect() {
    this.stop()
  }

  start = () => {
    if (this.delayValue > 0) this.timeout = setTimeout(() => this.close(), this.delayValue)
  }

  stop = () => {
    clearTimeout(this.timeout)
  }

  close() {
    this.element.remove()
  }
}
