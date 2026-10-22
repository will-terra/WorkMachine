import { extractJob, extractProfile } from "./extract.js"
import { loadSettings } from "./config.js"
import { localize, t } from "./i18n.js"

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

localize()
localize(personTemplate.content)

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
  if (!job.description) return t("noDescription")
  const size = t("descriptionSize", job.description.length.toLocaleString(t("lang")))
  return posting.partial_score ? t("partialNote", size) : size
}

// What WorkMachine already knows about this job, and only the buttons that still make sense.
function showPosting(posting) {
  found.replaceChildren()
  found.hidden = !posting.found
  if (!posting.found) return

  const status = posting.application_status
  found.append(
    line(t(posting.partial_score ? "alreadyInPartial" : "alreadyIn", posting.score), "strong"),
    line(posting.summary, "muted small"),
    link(t("openInWorkMachine"), posting.app_url)
  )
  descriptionInfo.textContent = describeDescription(posting)
  saveButton.textContent = t("updateInWorkMachine")
  document.getElementById("saved-option").hidden = Boolean(status)
  applyButton.hidden = Boolean(status) && status !== "saved"
  applyButton.textContent = t(status === "saved" ? "markApplied" : "saveApplied")
}

async function showJob() {
  try {
    job = (await inject(extractJob)) || {}
  } catch (_) {
    statusLine.textContent = t("cantRead")
    return
  }

  for (const name of JOB_FIELDS) jobForm.elements[name].value = job[name] || ""
  descriptionInfo.textContent = describeDescription()
  statusLine.textContent = t(job.title ? "checkAndSave" : "noTitle")
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
  button.textContent = t("saving")

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
    const headline = applying ? t("inApplied", body.score)
      : body.duplicate ? t("updatedJob", body.score) : t("savedJob", body.score, body.remote_scope)
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
  output.replaceChildren(`${text} (${contact.kind_label}) · `, link(t("open"), contact.app_url))
  const button = form.querySelector("button")
  button.textContent = t("updateContact")
  button.title = t("updateContactHint")
}

async function lookupContact(form) {
  const linkedinUrl = form.elements.linkedin_url.value
  const response = linkedinUrl && await chrome.runtime.sendMessage({ type: "lookupContact", linkedinUrl })
  if (response?.ok && response.body.found) showContact(form, response.body, t("alreadyContact"))
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
    showContact(form, response.body, t(response.body.duplicate ? "updatedContact" : "savedContact"))
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
    statusLine.textContent = t("cantRead")
    return
  }

  for (const name of ["name", "headline", "company"]) contactForm.elements[name].value = person[name] || ""
  contactForm.elements.linkedin_url.value = person.linkedin_url || tab.url
  contactForm.elements.kind.value = guessKind(person.headline || "")
  statusLine.textContent = t(person.name ? "saveToContacts" : "noName")
  contactForm.hidden = false
  contactForm.addEventListener("submit", saveContact)
  lookupContact(contactForm)
}

loadSettings().then(async ({ token }) => {
  if (!token) {
    statusLine.textContent = t("setupToken")
    return
  }

  tab = (await chrome.tabs.query({ active: true, currentWindow: true }))[0]
  if (!tab?.id || !/^https?:/.test(tab.url || "")) {
    statusLine.textContent = t("openJobPage")
  } else if (LINKEDIN_PROFILE.test(tab.url)) {
    showProfile()
  } else {
    showJob()
  }
})
