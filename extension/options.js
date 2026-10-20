import { loadSettings, saveSettings } from "./config.js"

const form = document.getElementById("options-form")
const message = document.getElementById("message")

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
  show("Opções salvas.", true)
})

document.getElementById("test").addEventListener("click", async () => {
  await saveSettings({ server: form.elements.server.value, token: form.elements.token.value })
  const response = await chrome.runtime.sendMessage({ type: "ping" })
  show(response?.ok ? "Conectado ao WorkMachine." : response?.error || "Falhou.", response?.ok)
})
