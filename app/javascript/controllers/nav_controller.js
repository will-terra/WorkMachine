import { Controller } from "@hotwired/stimulus"

// The sections bar: on phones it is one line that scrolls sideways; the current section is
// brought to the middle so it is always in view.
export default class extends Controller {
  connect() {
    const current = this.element.querySelector("[aria-current=page]")
    if (!current || this.element.scrollWidth <= this.element.clientWidth) return

    this.element.scrollLeft = current.offsetLeft - (this.element.clientWidth - current.offsetWidth) / 2
  }
}
