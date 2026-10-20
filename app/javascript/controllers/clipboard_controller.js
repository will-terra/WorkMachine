import { Controller } from "@hotwired/stimulus"

// Copies the source target's text. Falls back to selecting it when the Clipboard API is blocked.
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
    this.buttonTarget.classList.add("text-ok", "border-ok")
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.buttonTarget.textContent = original
      this.buttonTarget.classList.remove("text-ok", "border-ok")
    }, 1500)
  }
}
