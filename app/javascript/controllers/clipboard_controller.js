import { Controller } from "@hotwired/stimulus"
import { t } from "i18n"

// Copies the source target's text and shows "Copiado" on the button for a moment. Falls back to
// selecting the text when the Clipboard API is blocked.
export default class extends Controller {
  static targets = ["source", "button"]

  async copy() {
    const text = this.sourceTarget.value ?? this.sourceTarget.textContent
    try {
      await navigator.clipboard.writeText(text.trim())
      this.flash(t("copy.copied"))
    } catch {
      const range = document.createRange()
      range.selectNodeContents(this.sourceTarget)
      const selection = window.getSelection()
      selection.removeAllRanges()
      selection.addRange(range)
      this.flash(t("copy.selected"))
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
