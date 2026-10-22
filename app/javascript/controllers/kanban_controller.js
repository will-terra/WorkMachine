import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

// Drag and drop between status columns. Each drop PATCHes the card's move URL and
// applies the Turbo Stream answer (updated card and column counters).
export default class extends Controller {
  static targets = ["column"]

  connect() {
    this.sortables = this.columnTargets.map((column) =>
      Sortable.create(column, {
        group: "kanban",
        animation: 150,
        // On touch screens a swipe scrolls the board; a long press picks the card up.
        delay: 180,
        delayOnTouchOnly: true,
        ghostClass: "kanban-ghost",
        filter: "a, button, [popover]",
        preventOnFilter: false,
        onStart: () => { this.element.dataset.dragging = "true" },
        onEnd: (event) => {
          delete this.element.dataset.dragging
          this.move(event)
        }
      })
    )
  }

  disconnect() {
    this.sortables.forEach((sortable) => sortable.destroy())
  }

  async move({ item, from, to, oldIndex, newIndex }) {
    if (from === to && oldIndex === newIndex) return

    const response = await fetch(item.dataset.moveUrl, {
      method: "PATCH",
      headers: {
        "Accept": "text/vnd.turbo-stream.html",
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content
      },
      body: JSON.stringify({ status: to.dataset.status, position: newIndex })
    })

    if (response.ok) {
      Turbo.renderStreamMessage(await response.text())
    } else {
      Turbo.visit(window.location.href, { action: "replace" })
    }
  }
}
