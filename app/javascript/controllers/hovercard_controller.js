import { Controller } from "@hotwired/stimulus"

// Kanban card details: a popover (top layer, so the column's scroll does not clip it) shown
// beside the card on hover or focus. A short delay lets the pointer reach the links inside it.
export default class extends Controller {
  static targets = ["panel"]

  connect() {
    this.closeNow = () => this.close()
    document.addEventListener("dragstart", this.closeNow)
    document.addEventListener("scroll", this.closeNow, { capture: true, passive: true })
  }

  disconnect() {
    document.removeEventListener("dragstart", this.closeNow)
    document.removeEventListener("scroll", this.closeNow, { capture: true })
    this.close()
  }

  show() {
    clearTimeout(this.timer)
    if (!this.hasPanelTarget || this.element.closest("[data-dragging]")) return

    this.timer = setTimeout(() => {
      if (!this.panelTarget.matches(":popover-open")) this.panelTarget.showPopover()
      this.place()
    }, 150)
  }

  hide(event) {
    if (event?.relatedTarget && this.element.contains(event.relatedTarget)) return

    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.close(), 150)
  }

  close() {
    clearTimeout(this.timer)
    if (this.hasPanelTarget && this.panelTarget.matches(":popover-open")) this.panelTarget.hidePopover()
  }

  place() {
    const gap = 8
    const card = this.element.getBoundingClientRect()
    const panel = this.panelTarget.getBoundingClientRect()
    let left = card.right + gap
    if (left + panel.width > window.innerWidth - gap) left = Math.max(gap, card.left - panel.width - gap)
    const top = Math.min(Math.max(gap, card.top), window.innerHeight - panel.height - gap)

    Object.assign(this.panelTarget.style, { position: "fixed", inset: "auto", left: `${left}px`, top: `${top}px` })
  }
}
