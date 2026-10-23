import { Controller } from "@hotwired/stimulus"

// Remembers which Radar sections are open or folded, in a cookie the server reads to render the
// page as the person left it (RadarController#folds).
export default class extends Controller {
  remember(event) {
    const folds = this.read()
    folds[event.target.id] = event.target.open ? 1 : 0
    document.cookie = `radar_folds=${encodeURIComponent(JSON.stringify(folds))}; path=/; max-age=31536000; SameSite=Lax`
  }

  read() {
    const cookie = document.cookie.split("; ").find((pair) => pair.startsWith("radar_folds="))
    try {
      return cookie ? JSON.parse(decodeURIComponent(cookie.slice("radar_folds=".length))) : {}
    } catch {
      return {}
    }
  }
}
