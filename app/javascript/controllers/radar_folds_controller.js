import { Controller } from "@hotwired/stimulus"

// Remembers which Radar sections the person opened or folded, in a cookie the server reads to
// render the page as they left it (RadarController#folds). Only clicks on a title count: sections
// opened by the page itself keep following their defaults.
export default class extends Controller {
  remember(event) {
    const details = event.currentTarget.closest("details")
    const folds = this.read()
    folds[details.dataset.fold] = details.open ? 0 : 1 // the click comes before the section toggles
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
