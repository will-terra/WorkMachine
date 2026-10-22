import { Controller } from "@hotwired/stimulus"

// Mensagens: picks a template from the list (also from the address, #message_template_3), fills
// {{nome}}, {{cargo}} and {{empresa}} from the fields and {{meu_resumo}} and {{minha_stack}} from
// the profile, and shows what is still empty in amber. "Editar modelo" opens the raw text, and the
// preview follows it while typing.
export default class extends Controller {
  static targets = ["item", "name", "input", "preview", "source", "counter", "editor", "form", "body", "editLink", "editToggle", "copyButton"]

  connect() {
    const fromHash = this.itemTargets.find((item) => `#${item.id}` === window.location.hash)
    this.select(fromHash || this.selected)
  }

  pick(event) {
    this.select(event.currentTarget)
    window.history.replaceState(window.history.state, "", `#${event.currentTarget.id}`)
  }

  select(item) {
    if (!item) return
    this.itemTargets.forEach((other) => other.setAttribute("aria-selected", other === item ? "true" : "false"))
    this.nameTarget.textContent = item.dataset.name
    this.bodyTarget.value = item.dataset.body
    this.formTarget.action = item.dataset.updateUrl
    this.editLinkTarget.href = item.dataset.editUrl
    this.render()
  }

  fill(event) {
    const option = event.target.selectedOptions[0]
    for (const key of ["nome", "cargo", "empresa"]) {
      const input = this.inputTargets.find((field) => field.name === key)
      if (option.dataset[key]) input.value = option.dataset[key]
    }
    this.render()
  }

  edit() {
    this.selected.dataset.body = this.bodyTarget.value
    this.render()
  }

  toggleEdit() {
    this.editorTarget.hidden = !this.editorTarget.hidden
    this.editToggleTarget.textContent = this.editorTarget.hidden ? "Editar modelo" : "Fechar edição"
    if (!this.editorTarget.hidden) this.bodyTarget.focus()
  }

  render() {
    const item = this.selected
    if (!item) return
    const values = { ...JSON.parse(item.dataset.profile || "{}") }
    this.inputTargets.forEach((input) => { values[input.name] = input.value.trim() })

    const nodes = []
    let text = ""
    for (const part of item.dataset.body.split(/(\{\{\s*\w+\s*\}\})/).filter(Boolean)) {
      const key = part.match(/^\{\{\s*(\w+)\s*\}\}$/)?.[1]
      const value = key && values[key]
      if (!key) {
        nodes.push(document.createTextNode(part))
        text += part
      } else {
        const span = document.createElement("span")
        span.textContent = value || part
        span.className = value ? "text-accent-text" : "rounded-[2px] bg-warn-soft-2 text-warn-text"
        nodes.push(span)
        text += value || part
      }
    }
    this.previewTarget.replaceChildren(...nodes)
    this.sourceTarget.value = text

    const max = parseInt(item.dataset.max, 10)
    const over = !!max && text.length > max
    this.counterTarget.textContent = max ? `${text.length} / ${max} caracteres` : `${text.length} caracteres`
    this.counterTarget.classList.toggle("text-warn-strong", over)
    this.counterTarget.classList.toggle("text-muted", !over)
  }

  async copy() {
    try {
      await navigator.clipboard.writeText(this.sourceTarget.value)
      this.copyButtonTarget.textContent = "Copiado"
    } catch {
      this.sourceTarget.classList.remove("hidden")
      this.sourceTarget.select()
      this.copyButtonTarget.textContent = "Selecionado: Ctrl+C"
    }
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => { this.copyButtonTarget.textContent = "Copiar mensagem" }, 1600)
  }

  get selected() {
    return this.itemTargets.find((item) => item.getAttribute("aria-selected") === "true")
  }
}
