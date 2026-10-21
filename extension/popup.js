import { extractJob, extractProfile } from "./extract.js"
import { loadSettings } from "./config.js"

const JOB_FIELDS = ["title", "company", "location_text", "url"]
const CONTACT_FIELDS = ["name", "headline", "company", "linkedin_url", "kind"]
const LINKEDIN_PROFILE = /^https:\/\/([\w-]+\.)?linkedin\.com\/in\//

const statusLine = document.getElementById("status")
const found = document.getElementById("found")
const jobForm = document.getElementById("job-form")
const saveButton = document.getElementById("save-button")
const applyButton = document.getElementById("apply-button")
const descriptionInfo = document.getElementById("description-info")
const result = document.getElementById("result")
const people = document.getElementById("people")
const contactForm = document.getElementById("contact-form")
const personTemplate = document.getElementById("person-template")
let tab
let job = {}

document.getElementById("open-options").addEventListener("click", (event) => {
  event.preventDefault()
  chrome.runtime.openOptionsPage()
})

function line(text, className = "") {
  const paragraph = document.createElement("p")
  paragraph.className = className
  paragraph.textContent = text
  return paragraph
}

function link(text, href) {
  const anchor = document.createElement("a")
  Object.assign(anchor, { textContent: text, href, target: "_blank" })
  return anchor
}

// Recruiter, talent, RH… → recruiter; manager, lead, head, CTO… → manager. Recruiter when unsure.
function guessKind(headline) {
  if (/recruit|recrut|talent|sourc|people|human|\bhr\b|\brh\b|headhunt/i.test(headline)) return "recruiter"
  return /manager|gerente|head|lead|l[ií]der|director|diretor|\bcto\b|\bvp\b|founder|fundador|\bceo\b/i.test(headline) ? "manager" : "recruiter"
}

async function inject(func) {
  const [{ result: value }] = await chrome.scripting.executeScript({ target: { tabId: tab.id }, func })
  return value
}

function describeDescription(posting = {}) {
  if (!job.description) return "Sem descrição nesta página; a nota vai usar só o título."
  const size = `Descrição: ${job.description.length.toLocaleString("pt-BR")} caracteres.`
  return posting.partial_score ? `${size} No WorkMachine a nota está parcial: atualize para completar.` : size
}

// What WorkMachine already knows about this job, and only the buttons that still make sense.
function showPosting(posting) {
  found.replaceChildren()
  found.hidden = !posting.found
  if (!posting.found) return

  const status = posting.application_status
  found.append(
    line(`Já está no WorkMachine · nota ${posting.score}${posting.partial_score ? " (parcial)" : ""}`, "strong"),
    line(posting.summary, "muted small"),
    link("Abrir no WorkMachine", posting.app_url)
  )
  descriptionInfo.textContent = describeDescription(posting)
  saveButton.textContent = "Atualizar no WorkMachine"
  document.getElementById("saved-option").hidden = Boolean(status)
  applyButton.hidden = Boolean(status) && status !== "saved"
  applyButton.textContent = status === "saved" ? "Marcar como aplicada" : "Salvar em aplicadas"
}

async function showJob() {
  try {
    job = (await inject(extractJob)) || {}
  } catch (_) {
    statusLine.textContent = "Não consegui ler esta página."
    return
  }

  for (const name of JOB_FIELDS) jobForm.elements[name].value = job[name] || ""
  descriptionInfo.textContent = describeDescription()
  statusLine.textContent = job.title ? "Confira e salve:" : "Não achei o título. Preencha antes de salvar:"
  jobForm.hidden = false
  jobForm.elements.title.focus()
  showPeople(job.people || [])

  const lookup = await chrome.runtime.sendMessage({ type: "lookup", job: { url: job.url, company: job.company, title: job.title } })
  if (lookup?.ok) showPosting(lookup.body)
}

jobForm.addEventListener("submit", async (event) => {
  event.preventDefault()
  const button = event.submitter || saveButton
  const applying = button === applyButton
  const label = button.textContent
  button.disabled = true
  button.textContent = "Salvando…"

  const { people: _people, ...extracted } = job
  const edited = Object.fromEntries(JOB_FIELDS.map((name) => [name, jobForm.elements[name].value.trim()]))
  const response = await chrome.runtime.sendMessage({
    type: "save",
    job: { ...extracted, ...edited },
    applicationStatus: applying ? "applied" : jobForm.elements.create_application.checked ? "saved" : null,
    tab: { id: tab.id, url: tab.url }
  })

  button.disabled = false
  button.textContent = label
  result.hidden = false

  if (response?.ok) {
    const { body } = response
    const headline = applying ? `Em aplicadas · nota ${body.score}`
      : body.duplicate ? `Atualizada · nota ${body.score}` : `Salva · nota ${body.score} · ${body.remote_scope}`
    result.replaceChildren(line(headline, "ok"))
    statusLine.hidden = true
    showPosting({ ...body, found: true })
  } else {
    result.replaceChildren(line(response?.error || "Erro desconhecido.", "error"))
  }
})

function showContact(form, contact, text) {
  const output = form.querySelector("[data-result]")
  output.className = "small ok"
  output.replaceChildren(`${text} (${contact.kind_label}) · `, link("Abrir", contact.app_url))
  const button = form.querySelector("button")
  button.textContent = "Atualizar contato"
  button.title = "Só preenche o que estiver vazio no WorkMachine."
}

async function lookupContact(form) {
  const linkedinUrl = form.elements.linkedin_url.value
  const response = linkedinUrl && await chrome.runtime.sendMessage({ type: "lookupContact", linkedinUrl })
  if (response?.ok && response.body.found) showContact(form, response.body, "Já está nos contatos")
}

async function saveContact(event) {
  event.preventDefault()
  const form = event.currentTarget
  const fromJob = form !== contactForm
  if (fromJob) form.elements.company.value = jobForm.elements.company.value.trim()
  const contact = Object.fromEntries(CONTACT_FIELDS.map((name) => [name, form.elements[name].value.trim()]))
  const button = form.querySelector("button")
  button.disabled = true

  const response = await chrome.runtime.sendMessage({
    type: "saveContact",
    contact,
    job: fromJob ? { title: jobForm.elements.title.value.trim(), url: jobForm.elements.url.value.trim() } : null
  })

  button.disabled = false
  if (response?.ok) {
    showContact(form, response.body, response.body.duplicate ? "Atualizado nos contatos" : "Salvo nos contatos")
  } else {
    const output = form.querySelector("[data-result]")
    output.className = "small error"
    output.textContent = response?.error || "Erro desconhecido."
  }
}

// "Meet the hiring team" of a LinkedIn job: one small form per person.
function showPeople(list) {
  for (const person of list) {
    const form = personTemplate.content.firstElementChild.cloneNode(true)
    for (const name of ["name", "headline", "linkedin_url"]) form.elements[name].value = person[name] || ""
    form.elements.kind.value = guessKind(person.headline || "")
    form.addEventListener("submit", saveContact)
    people.append(form)
    people.hidden = false
    lookupContact(form)
  }
}

async function showProfile() {
  let person
  try {
    person = (await inject(extractProfile)) || {}
  } catch (_) {
    statusLine.textContent = "Não consegui ler esta página."
    return
  }

  for (const name of ["name", "headline", "company"]) contactForm.elements[name].value = person[name] || ""
  contactForm.elements.linkedin_url.value = person.linkedin_url || tab.url
  contactForm.elements.kind.value = guessKind(person.headline || "")
  statusLine.textContent = person.name ? "Salvar em Contatos:" : "Não achei o nome. Preencha antes de salvar:"
  contactForm.hidden = false
  contactForm.addEventListener("submit", saveContact)
  lookupContact(contactForm)
}

loadSettings().then(async ({ token }) => {
  if (!token) {
    statusLine.textContent = "Primeiro, configure o token nas Opções."
    return
  }

  tab = (await chrome.tabs.query({ active: true, currentWindow: true }))[0]
  if (!tab?.id || !/^https?:/.test(tab.url || "")) {
    statusLine.textContent = "Abra a página de uma vaga ou um perfil do LinkedIn e clique de novo."
  } else if (LINKEDIN_PROFILE.test(tab.url)) {
    showProfile()
  } else {
    showJob()
  }
})
