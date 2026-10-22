import { Controller } from "@hotwired/stimulus"

// Radar: shows only the tasks of the chosen frequency (Todo dia, Toda semana, Uma vez). The choice
// goes in the address (#weekly), and a link to a task (#cadastros) opens its frequency.
export default class extends Controller {
  static targets = ["option", "panel"]

  connect() {
    const hash = decodeURIComponent(window.location.hash.slice(1))
    const panel = hash ? document.getElementById(hash)?.closest("[data-cadence]") : null
    this.show(panel?.dataset.cadence || this.optionTargets.find((option) => option.checked)?.value)
  }

  change(event) {
    this.show(event.target.value)
    window.history.replaceState(window.history.state, "", `#${event.target.value}`)
  }

  show(key) {
    this.optionTargets.forEach((option) => { option.checked = option.value === key })
    this.panelTargets.forEach((panel) => { panel.hidden = panel.dataset.cadence !== key })
  }
}
