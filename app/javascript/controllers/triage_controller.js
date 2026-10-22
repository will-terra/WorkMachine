import { Controller } from "@hotwired/stimulus"

// Vagas: the list and the detail of the selected posting side by side. A click or ↑/↓ (j/k) picks
// a posting and loads its detail in the frame; S, A and D press Salvar, Salvar em aplicadas and
// Descartar of the detail. A posting that no longer belongs to the list (saved from "Novas", say)
// leaves it, and the next one is picked. Shortcuts stay off while typing in a field.
// On small screens the detail is hidden and a click opens the posting's page instead.
export default class extends Controller {
  static targets = ["item", "frame"]
  static values = { tab: String }

  connect() {
    this.selectedId = this.itemTargets.find((item) => item.getAttribute("aria-selected") === "true")?.dataset.id
  }

  pick(event) {
    if (!this.detailVisible) return
    event.preventDefault()
    this.select(event.currentTarget)
  }

  keydown(event) {
    if (event.metaKey || event.ctrlKey || event.altKey || !this.detailVisible) return
    const target = event.target
    if (target.isContentEditable || /^(INPUT|SELECT|TEXTAREA)$/.test(target.tagName)) return

    const key = event.key.toLowerCase()
    const index = this.itemTargets.findIndex((item) => item.dataset.id === this.selectedId)
    if (key === "arrowdown" || key === "j") {
      event.preventDefault()
      this.select(this.itemTargets[Math.min(index + 1, this.itemTargets.length - 1)])
    } else if (key === "arrowup" || key === "k") {
      event.preventDefault()
      this.select(this.itemTargets[Math.max(index - 1, 0)])
    } else if (["s", "a", "d"].includes(key)) {
      const button = this.frameTarget.querySelector(`[data-shortcut="${key}"]`)
      if (button && !button.disabled) {
        event.preventDefault()
        button.click()
      }
    }
  }

  select(item, { scroll = true } = {}) {
    if (!item) return
    this.selectedId = item.dataset.id
    this.itemTargets.forEach((other) => other.setAttribute("aria-selected", other === item ? "true" : "false"))
    this.load(this.frameTarget)

    const url = new URL(window.location.href)
    url.searchParams.set("selected", item.dataset.id)
    window.history.replaceState(window.history.state, "", url)
    if (scroll) item.scrollIntoView({ block: "nearest" })
  }

  // The item comes back from the server after Salvar, Descartar…: it keeps the selection, or
  // leaves the list and hands the selection to its neighbour.
  itemTargetConnected(item) {
    if (item.dataset.id !== this.selectedId) return
    if (!this.leaves(item)) return item.setAttribute("aria-selected", "true")

    const items = this.itemTargets
    const index = items.indexOf(item)
    const next = items[index + 1] || items[index - 1]
    item.remove()
    if (next) {
      this.select(next)
    } else {
      this.selectedId = null
      this.frameTarget.replaceChildren()
    }
  }

  // A detail rendered by the server for a posting that is no longer the selected one.
  frameTargetConnected(frame) {
    if (this.selectedId) this.load(frame)
  }

  load(frame) {
    const item = this.itemTargets.find((other) => other.dataset.id === this.selectedId)
    if (!item || frame.querySelector("[data-posting-id]")?.dataset.postingId === this.selectedId) return
    frame.src = item.href
  }

  leaves(item) {
    switch (this.tabValue) {
      case "all": return false
      case "auto": return item.dataset.triage !== "dismissed" || item.dataset.auto !== "true"
      default: return item.dataset.triage !== this.tabValue
    }
  }

  get detailVisible() {
    return this.hasFrameTarget && this.frameTarget.offsetParent !== null
  }
}
