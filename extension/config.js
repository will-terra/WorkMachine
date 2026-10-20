// Settings saved by the options page (chrome.storage.local).
export const DEFAULT_SERVER = "http://localhost:3000"

export async function loadSettings() {
  const { server, token } = await chrome.storage.local.get(["server", "token"])
  return { server: (server || DEFAULT_SERVER).replace(/\/+$/, ""), token: token || "" }
}

export async function saveSettings({ server, token }) {
  await chrome.storage.local.set({ server: server.trim().replace(/\/+$/, ""), token: token.trim() })
}
