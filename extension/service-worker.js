// Sends the requests to the WorkMachine server. Requests leave from here (not from the page),
// so host_permissions is enough and the Rails app needs no CORS.
// It also keeps the icon badge: on a LinkedIn job already in WorkMachine, the badge shows its
// score. Only the tab's address is used for that; the page itself is read only when you click.
import { loadSettings } from "./config.js"

const BADGE_COLORS = { applied: "#1d7448", dismissed: "#675e62", other: "#a8132d" }
const DEFAULT_TITLE = "Salvar no WorkMachine"
const badgeUrls = new Map()

async function request(path, options = {}) {
  const { server, token } = await loadSettings()
  if (!token) return { ok: false, error: "Configure o token nas opções da extensão." }

  try {
    const response = await fetch(`${server}${path}`, {
      ...options,
      headers: { "Content-Type": "application/json", "Accept": "application/json", "Authorization": `Bearer ${token}` }
    })
    const body = await response.json().catch(() => ({}))
    return response.ok ? { ok: true, body } : { ok: false, error: body.error || (body.errors || []).join(", ") || `Erro ${response.status}` }
  } catch (_) {
    return { ok: false, error: `Não consegui falar com ${server}. O WorkMachine está rodando?` }
  }
}

function query(params) {
  return new URLSearchParams(Object.entries(params || {}).filter(([, value]) => value)).toString()
}

// linkedin.com/jobs/view/123 and /jobs/search/?currentJobId=123 → https://www.linkedin.com/jobs/view/123
function linkedInJobUrl(address) {
  let url
  try { url = new URL(address) } catch (_) { return null }
  if (!/(^|\.)linkedin\.com$/.test(url.hostname)) return null

  const id = url.pathname.match(/\/jobs\/view\/(?:[^/]*-)?(\d+)/)?.[1] || url.searchParams.get("currentJobId")
  return /^\d+$/.test(id || "") ? `https://www.linkedin.com/jobs/view/${id}` : null
}

function paintBadge(tabId, { text = "", color = BADGE_COLORS.other, title = DEFAULT_TITLE } = {}) {
  // The tab may be gone by the time the lookup answers.
  Promise.all([
    chrome.action.setBadgeText({ tabId, text }),
    chrome.action.setBadgeBackgroundColor({ tabId, color }),
    chrome.action.setBadgeTextColor?.({ tabId, color: "#ffffff" }),
    chrome.action.setTitle({ tabId, title })
  ]).catch(() => {})
}

async function updateBadge(tabId, address) {
  const url = linkedInJobUrl(address)
  badgeUrls.set(tabId, url)
  if (!url) return paintBadge(tabId)

  const response = await request(`/api/v1/job_postings/lookup?${query({ url })}`)
  if (badgeUrls.get(tabId) !== url) return // the tab moved on to another job meanwhile
  if (!response.ok) return paintBadge(tabId)

  const job = response.body
  if (!job.found) return paintBadge(tabId, { title: "WorkMachine: vaga ainda não salva. Clique para salvar." })

  const applied = job.application_status && job.application_status !== "saved"
  paintBadge(tabId, {
    text: String(job.score),
    color: applied ? BADGE_COLORS.applied : job.triage === "dismissed" ? BADGE_COLORS.dismissed : BADGE_COLORS.other,
    title: `WorkMachine: nota ${job.score}${job.partial_score ? " (parcial)" : ""} · ${job.summary}`
  })
}

chrome.tabs.onUpdated.addListener((tabId, changeInfo) => {
  if (changeInfo.url) updateBadge(tabId, changeInfo.url)
})
chrome.tabs.onActivated.addListener(({ tabId }) => {
  chrome.tabs.get(tabId).then((tab) => updateBadge(tabId, tab.url)).catch(() => {})
})
chrome.tabs.onRemoved.addListener((tabId) => badgeUrls.delete(tabId))

const handlers = {
  ping: () => request("/api/v1/ping"),
  lookup: ({ job }) => request(`/api/v1/job_postings/lookup?${query(job)}`),
  save: async ({ job, applicationStatus, tab }) => {
    const response = await request("/api/v1/job_postings", {
      method: "POST",
      body: JSON.stringify({ job_posting: job, application_status: applicationStatus })
    })
    if (response.ok && tab) updateBadge(tab.id, tab.url)
    return response
  },
  lookupContact: ({ linkedinUrl }) => request(`/api/v1/contacts/lookup?${query({ linkedin_url: linkedinUrl })}`),
  saveContact: ({ contact, job }) => request("/api/v1/contacts", { method: "POST", body: JSON.stringify({ contact, job }) })
}

chrome.runtime.onMessage.addListener((message, _sender, sendResponse) => {
  const handler = handlers[message.type]
  if (!handler) return false
  handler(message).then(sendResponse)
  return true
})
