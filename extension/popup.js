import { extractJob } from "./extract.js"
import { loadSettings } from "./config.js"

const form = document.getElementById("job-form")
const statusLine = document.getElementById("status")
const result = document.getElementById("result")
let job = {}

document.getElementById("open-options").addEventListener("click", (event) => {
  event.preventDefault()
  chrome.runtime.openOptionsPage()
})

async function readActiveTab() {
  const [tab] = await chrome.tabs.query({ active: true, currentWindow: true })
  if (!tab?.id || !/^https?:/.test(tab.url || "")) {
    statusLine.textContent = "Abra a página de uma vaga e clique de novo."
    return
  }

  try {
    const [{ result: extracted }] = await chrome.scripting.executeScript({ target: { tabId: tab.id }, func: extractJob })
    job = extracted || {}
  } catch (_) {
    statusLine.textContent = "Não consegui ler esta página."
    return
  }

  for (const name of ["title", "company", "location_text", "url"]) form.elements[name].value = job[name] || ""
  document.getElementById("description-info").textContent = job.description
    ? `Descrição: ${job.description.length.toLocaleString("pt-BR")} caracteres.`
    : "Sem descrição nesta página; a nota vai usar só o título."
  statusLine.textContent = job.title ? "Confira e salve:" : "Não achei o título. Preencha antes de salvar:"
  form.hidden = false
  form.elements.title.focus()
}

form.addEventListener("submit", async (event) => {
  event.preventDefault()
  const button = form.querySelector("button")
  button.disabled = true
  button.textContent = "Salvando…"

  const edited = Object.fromEntries(["title", "company", "location_text", "url"].map((name) => [name, form.elements[name].value.trim()]))
  const response = await chrome.runtime.sendMessage({
    type: "save",
    job: { ...job, ...edited },
    createApplication: form.elements.create_application.checked
  })

  button.disabled = false
  button.textContent = "Salvar no WorkMachine"
  result.hidden = false
  result.replaceChildren()

  if (response?.ok) {
    const { body } = response
    const headline = document.createElement("p")
    headline.className = "ok"
    headline.textContent = body.duplicate ? `Já estava salva · nota ${body.score}` : `Salva · nota ${body.score} · ${body.remote_scope}`
    const link = document.createElement("a")
    link.href = body.app_url
    link.target = "_blank"
    link.textContent = "Abrir no WorkMachine"
    result.append(headline, link)
    form.hidden = true
    statusLine.hidden = true
  } else {
    const error = document.createElement("p")
    error.className = "error"
    error.textContent = response?.error || "Erro desconhecido."
    result.append(error)
  }
})

loadSettings().then(({ token }) => {
  if (!token) {
    statusLine.textContent = "Primeiro, configure o token nas Opções."
    return
  }
  readActiveTab()
})
