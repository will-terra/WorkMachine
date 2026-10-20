// Sends the requests to the WorkMachine server. Requests leave from here (not from the page),
// so host_permissions is enough and the Rails app needs no CORS.
import { loadSettings } from "./config.js"

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

chrome.runtime.onMessage.addListener((message, _sender, sendResponse) => {
  if (message.type === "save") {
    request("/api/v1/job_postings", {
      method: "POST",
      body: JSON.stringify({ job_posting: message.job, create_application: message.createApplication })
    }).then(sendResponse)
    return true
  }
  if (message.type === "ping") {
    request("/api/v1/ping").then(sendResponse)
    return true
  }
  return false
})
