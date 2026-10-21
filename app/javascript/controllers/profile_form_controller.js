import { Controller } from "@hotwired/stimulus"

// Profile form: adds and removes skill rows and shows the chosen area's suggestions (skills and
// titles), which are added with a click.
export default class extends Controller {
  static targets = ["skills", "skill", "skillTemplate", "destroy", "skillSuggestions", "area",
                    "titlesPt", "titlesEn", "titlesPtSuggestions", "titlesEnSuggestions"]
  static values = { areas: Object }

  connect() {
    this.areaChanged()
  }

  addSkill(event, skill = {}) {
    // Rails only reads numbered rows (profile[skills][0][name]…), so new rows get a numeric index too.
    const html = this.skillTemplateTarget.innerHTML.replaceAll("NEW_INDEX", `${Date.now()}${Math.floor(Math.random() * 1000)}`)
    this.skillsTarget.insertAdjacentHTML("beforeend", html)
    const row = this.skillsTarget.lastElementChild
    if (skill.name) row.querySelector("input[name$='[name]']").value = skill.name
    if (skill.level) row.querySelector("select").value = skill.level
    if (!skill.name) row.querySelector("input").focus()
    this.areaChanged()
  }

  removeSkill(event) {
    const row = event.target.closest("tr")
    row.querySelector("[data-profile-form-target='destroy']").value = "1"
    row.hidden = true
    this.areaChanged()
  }

  areaChanged() {
    const area = this.areasValue[this.hasAreaTarget ? this.areaTarget.value : ""]
    const current = this.skillNames()
    this.render(this.skillSuggestionsTarget, (area?.skills || []).filter(skill => !current.has(skill.name.toLowerCase())),
      skill => skill.name, skill => this.addSkill(null, skill))
    this.renderTitles(area?.titles_pt, this.titlesPtTarget, this.titlesPtSuggestionsTarget)
    this.renderTitles(area?.titles_en, this.titlesEnTarget, this.titlesEnSuggestionsTarget)
  }

  // private

  renderTitles(titles, textarea, container) {
    const current = new Set(textarea.value.split(/\n/).map(title => title.trim().toLowerCase()))
    this.render(container, (titles || []).filter(title => !current.has(title.toLowerCase())), title => title, title => {
      textarea.value = [textarea.value.trim(), title].filter(Boolean).join("\n")
      this.areaChanged()
    })
  }

  render(container, items, label, onClick) {
    container.replaceChildren(...items.map(item => {
      const button = document.createElement("button")
      button.type = "button"
      button.className = "chip cursor-pointer hover:border-ink"
      button.textContent = `+ ${label(item)}`
      button.addEventListener("click", () => onClick(item))
      return button
    }))
    if (items.length === 0) container.textContent = "—"
  }

  // Names and synonyms already in the table, so "Ruby on Rails" is not suggested next to "Rails".
  skillNames() {
    return new Set(this.skillTargets.filter(row => !row.hidden).flatMap(row => [
      row.querySelector("input[name$='[name]']").value,
      ...row.querySelector("input[name$='[synonyms]']").value.split(",")
    ]).map(name => name.trim().toLowerCase()).filter(Boolean))
  }
}
