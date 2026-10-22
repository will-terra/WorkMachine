import { Controller } from "@hotwired/stimulus"

// Copies the source target's text and shows "Copiado" on the button for a moment. Falls back to
// selecting the text when the Clipboard API is blocked.
export default class extends Controller {
  static targets = ["source", "button"]

  async copy() {
    const text = this.sourceTarget.value ?? this.sourceTarget.textContent
    try {
      await navigator.clipboard.writeText(text.trim())
      this.flash("Copiado")
    } catch {
      const range = document.createRange()
      range.selectNodeContents(this.sourceTarget)
      const selection = window.getSelection()
      selection.removeAllRanges()
      selection.addRange(range)
      this.flash("Selecionado: Ctrl+C")
    }
  }

  flash(label) {
    if (!this.hasButtonTarget) return
    const original = this.buttonTarget.dataset.label ||= this.buttonTarget.textContent
    this.buttonTarget.textContent = label
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => { this.buttonTarget.textContent = original }, 1600)
  }
}
