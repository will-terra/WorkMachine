import { Controller } from "@hotwired/stimulus"

// Turns desktop notifications (Web Push) on or off for this browser and sends a test.
export default class extends Controller {
  static targets = ["status", "enable", "disable", "test"]
  static values = { publicKey: String, subscribeUrl: String, unsubscribeUrl: String, testUrl: String }

  async connect() {
    if (!this.supported) return this.show("Este navegador não suporta notificações.", [])
    if (Notification.permission === "denied") return this.denied()
    this.render(await this.subscription())
  }

  get supported() {
    return "serviceWorker" in navigator && "PushManager" in window && "Notification" in window
  }

  async registration() {
    await navigator.serviceWorker.register("/service-worker.js")
    return navigator.serviceWorker.ready
  }

  async subscription() {
    return (await this.registration()).pushManager.getSubscription()
  }

  async enable() {
    const permission = await Notification.requestPermission()
    if (permission !== "granted") return this.denied()

    try {
      const registration = await this.registration()
      const subscription = await registration.pushManager.subscribe({ userVisibleOnly: true, applicationServerKey: this.applicationServerKey })
      await this.request("POST", this.subscribeUrlValue, subscription.toJSON())
      this.render(subscription)
    } catch (error) {
      this.show(`Não consegui ativar: ${error.message}`, ["enable"])
    }
  }

  async disable() {
    const subscription = await this.subscription()
    if (subscription) {
      await this.request("DELETE", this.unsubscribeUrlValue, { endpoint: subscription.endpoint })
      await subscription.unsubscribe()
    }
    this.render(null)
  }

  async test() {
    const result = await this.request("POST", this.testUrlValue, {})
    this.show(result.ok ? "Notificação de teste enviada. Ela deve aparecer em alguns segundos." : "Nenhum navegador recebeu o teste. Desative e ative de novo.", ["test", "disable"])
  }

  render(subscription) {
    if (subscription) {
      this.show("Notificações ativadas neste navegador.", ["test", "disable"])
    } else {
      this.show("Notificações desativadas neste navegador.", ["enable"])
    }
  }

  denied() {
    this.show("As notificações estão bloqueadas. Libere em: cadeado na barra de endereço → Notificações → Permitir, e recarregue a página.", [])
  }

  show(message, buttons) {
    this.statusTarget.textContent = message
    for (const name of ["enable", "disable", "test"]) this[`${name}Target`].hidden = !buttons.includes(name)
  }

  get applicationServerKey() {
    const base64 = this.publicKeyValue.replace(/-/g, "+").replace(/_/g, "/")
    const raw = atob(base64 + "=".repeat((4 - (base64.length % 4)) % 4))
    return Uint8Array.from(raw, (char) => char.charCodeAt(0))
  }

  async request(method, url, body) {
    const response = await fetch(url, {
      method,
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content
      },
      body: JSON.stringify(body)
    })
    return response.json().catch(() => ({ ok: response.ok }))
  }
}
