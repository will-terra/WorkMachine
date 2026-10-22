import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

// Rows of a nested form (the slots of a routine, the items of a slot): adds them from a <template>,
// removes them (marking _destroy on saved ones) and keeps the hidden position fields in the order
// shown, also after dragging a row by its handle.
export default class extends Controller {
  static targets = ["template", "list"]
  static values = { placeholder: String, handle: String }

  connect() {
    this.sortable = Sortable.create(this.listTarget, {
      handle: `[data-handle="${this.handleValue}"]`,
      animation: 150,
      ghostClass: "kanban-ghost",
      onEnd: () => this.renumber()
    })
  }

  disconnect() {
    this.sortable?.destroy()
  }

  add() {
    const index = `${Date.now()}${Math.floor(Math.random() * 1000)}`
    this.listTarget.insertAdjacentHTML("beforeend", this.templateTarget.innerHTML.replaceAll(this.placeholderValue, index))
    this.renumber()
    this.listTarget.lastElementChild?.querySelector("input[type=text]")?.focus()
  }

  remove(event) {
    const row = event.target.closest("[data-nested-row]")
    const destroy = row.querySelector(":scope > input[data-destroy]")
    if (destroy) {
      destroy.value = "1"
      row.hidden = true
    } else {
      row.remove()
    }
    this.renumber()
  }

  renumber() {
    const rows = [...this.listTarget.children].filter((row) => row.matches("[data-nested-row]") && !row.hidden)
    rows.forEach((row, index) => {
      const position = row.querySelector(":scope > input[data-position]")
      if (position) position.value = index
    })
  }
}
