import { Controller } from "@hotwired/stimulus"

// Radar: shows only the tasks of the chosen frequency (Todo dia, Toda semana, Uma vez). The choice
// goes in the address (#weekly), and a link to a task (#cadastros) opens its frequency, also from
// the same page (the "alertas para ativar" notice).
export default class extends Controller {
  static targets = ["option", "panel"]

  connect() {
    this.show(this.linkedPanel()?.dataset.cadence || this.optionTargets.find((option) => option.checked)?.value)
  }

  change(event) {
    this.show(event.target.value)
    window.history.replaceState(window.history.state, "", `#${event.target.value}`)
  }

  follow() {
    const panel = this.linkedPanel()
    if (!panel) return
    this.show(panel.dataset.cadence)
    document.getElementById(decodeURIComponent(window.location.hash.slice(1)))?.scrollIntoView()
  }

  show(key) {
    this.optionTargets.forEach((option) => { option.checked = option.value === key })
    this.panelTargets.forEach((panel) => { panel.hidden = panel.dataset.cadence !== key })
  }

  linkedPanel() {
    const hash = decodeURIComponent(window.location.hash.slice(1))
    return hash ? document.getElementById(hash)?.closest("[data-cadence]") : null
  }
}
