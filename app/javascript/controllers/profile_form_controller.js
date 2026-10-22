import { Controller } from "@hotwired/stimulus"

// Profile form: skill chips by level (Enter adds, × removes, the popover changes the level and
// the synonyms), terms to avoid, the chosen area's suggestions (skills and titles) and the
// "Prévia das notas" column, refreshed a moment after each change.
export default class extends Controller {
  static targets = ["form", "level", "typed", "skill", "avoid", "skillTemplate", "avoidTemplate", "skillSuggestions",
                    "area", "titlesPt", "titlesEn", "titlesPtSuggestions", "titlesEnSuggestions", "previewButton"]
  static values = { areas: Object }

  connect() {
    this.areaChanged()
    this.preview()
  }

  disconnect() {
    clearTimeout(this.previewTimer)
  }

  addTyped(event) {
    event.preventDefault()
    const input = event.target
    const names = input.value.split(",").map(name => name.trim()).filter(Boolean)
    names.forEach(name => this.addChip(input.dataset.level, name))
    input.value = ""
  }

  addChip(level, name, synonyms = []) {
    if (this.chipNames().has(name.toLowerCase())) return

    const avoid = level === "avoid"
    // Rails only reads numbered rows (profile[skills][0][name]…), so new chips get a numeric index too.
    const template = (avoid ? this.avoidTemplateTarget : this.skillTemplateTarget).innerHTML
    const html = template.replaceAll("NEW_INDEX", `${Date.now()}${Math.floor(Math.random() * 1000)}`)
    const list = this.levelTargets.find(element => element.dataset.level === level)
    const typed = list.querySelector("[data-profile-form-target='typed']")
    typed.insertAdjacentHTML("beforebegin", html)
    const chip = typed.previousElementSibling
    chip.querySelector("[data-field='name']").value = name
    chip.querySelector("[data-field='label']").textContent = name
    chip.querySelector(".skill-chip-remove").setAttribute("aria-label", `Remover ${name}`)
    if (!avoid) {
      chip.querySelector("[data-field='level']").value = level
      chip.querySelector("[data-field='synonyms']").value = synonyms.join(", ")
      this.styleChip(chip, level)
    }
    this.changed()
  }

  removeChip(event) {
    event.target.closest(".skill-chip").remove()
    this.changed()
  }

  // The level select inside the popover moves the chip to that level's row.
  levelChanged(event) {
    const chip = event.target.closest(".skill-chip")
    const level = event.target.value
    const list = this.levelTargets.find(element => element.dataset.level === level)
    list.querySelector("[data-profile-form-target='typed']").before(chip)
    this.styleChip(chip, level)
    chip.querySelector("[popover]").hidePopover()
    chip.querySelector("[data-field='label']").focus()
  }

  // Popovers open in the top layer; this puts the panel under its chip.
  placePopover(event) {
    if (event.newState !== "open") return

    const panel = event.target
    const anchor = panel.closest(".skill-chip").getBoundingClientRect()
    const width = panel.getBoundingClientRect().width
    const left = Math.min(Math.max(8, anchor.left), window.innerWidth - width - 8)
    Object.assign(panel.style, { position: "fixed", inset: "auto", left: `${left}px`, top: `${anchor.bottom + 6}px` })
  }

  areaChanged() {
    const area = this.areasValue[this.hasAreaTarget ? this.areaTarget.value : ""]
    const current = this.chipNames()
    this.render(this.skillSuggestionsTarget, (area?.skills || []).filter(skill => !current.has(skill.name.toLowerCase())),
      skill => skill.name, skill => this.addChip(skill.level || "important", skill.name, skill.synonyms || []))
    this.renderTitles(area?.titles_pt, this.titlesPtTarget, this.titlesPtSuggestionsTarget)
    this.renderTitles(area?.titles_en, this.titlesEnTarget, this.titlesEnSuggestionsTarget)
  }

  schedulePreview(event) {
    if (event?.target?.dataset?.profileFormTarget === "typed") return

    clearTimeout(this.previewTimer)
    this.previewTimer = setTimeout(() => this.preview(), 500)
  }

  preview() {
    if (this.hasFormTarget && this.hasPreviewButtonTarget) this.formTarget.requestSubmit(this.previewButtonTarget)
  }

  // private

  changed() {
    this.areaChanged()
    this.schedulePreview()
  }

  styleChip(chip, level) {
    chip.classList.toggle("skill-chip-essential", level === "essential")
  }

  renderTitles(titles, input, container) {
    const current = new Set(input.value.split(/[\n,]/).map(title => title.trim().toLowerCase()))
    this.render(container, (titles || []).filter(title => !current.has(title.toLowerCase())), title => title, title => {
      input.value = [ ...input.value.split(/[\n,]/).map(item => item.trim()).filter(Boolean), title ].join(", ")
      this.changed()
    })
  }

  render(container, items, label, onClick) {
    container.replaceChildren(...items.map(item => {
      const button = document.createElement("button")
      button.type = "button"
      button.className = "chip cursor-pointer hover:bg-ink/15"
      button.textContent = `+ ${label(item)}`
      button.addEventListener("click", () => onClick(item))
      return button
    }))
    if (items.length === 0) container.textContent = "—"
  }

  // Names and synonyms already in the chips, so "Ruby on Rails" is not suggested next to "Rails".
  chipNames() {
    return new Set([ ...this.skillTargets, ...this.avoidTargets ].flatMap(chip => [
      chip.querySelector("[data-field='name']").value,
      ...(chip.querySelector("[data-field='synonyms']")?.value || "").split(",")
    ]).map(name => name.trim().toLowerCase()).filter(Boolean))
  }
}
