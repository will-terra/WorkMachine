import { Controller } from "@hotwired/stimulus"

// Live preview of the message templates: fills {{nome}}, {{cargo}} and {{empresa}}
// from the inputs and updates each character counter.
export default class extends Controller {
  static targets = ["input", "template"]

  connect() {
    this.render()
  }

  render() {
    const values = Object.fromEntries(this.inputTargets.map((input) => [input.name, input.value.trim()]))

    this.templateTargets.forEach((template) => {
      const text = template.dataset.body.replace(/\{\{\s*(nome|cargo|empresa)\s*\}\}/g, (match, key) => values[key] || match)
      const max = parseInt(template.dataset.max, 10)
      template.querySelector("[data-role=preview]").textContent = text
      const counter = template.querySelector("[data-role=counter]")
      counter.textContent = max ? `${text.length} / ${max} caracteres` : `${text.length} caracteres`
      counter.classList.toggle("text-accent", !!max && text.length > max)
      counter.classList.toggle("font-semibold", !!max && text.length > max)
    })
  }
}
