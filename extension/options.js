import { loadSettings, saveSettings } from "./config.js"
import { localize, t } from "./i18n.js"

const form = document.getElementById("options-form")
const message = document.getElementById("message")

localize()

function show(text, ok) {
  message.textContent = text
  message.className = ok ? "ok" : "error"
}

loadSettings().then(({ server, token }) => {
  form.elements.server.value = server
  form.elements.token.value = token
})

form.addEventListener("submit", async (event) => {
  event.preventDefault()
  await saveSettings({ server: form.elements.server.value, token: form.elements.token.value })
  show(t("optionsSaved"), true)
})

document.getElementById("test").addEventListener("click", async () => {
  await saveSettings({ server: form.elements.server.value, token: form.elements.token.value })
  const response = await chrome.runtime.sendMessage({ type: "ping" })
  show(response?.ok ? t("connected") : response?.error || t("failed"), response?.ok)
})
