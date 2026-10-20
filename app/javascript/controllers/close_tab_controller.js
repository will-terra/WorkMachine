import { Controller } from "@hotwired/stimulus"

// After a successful submit, closes the tab when it was opened just for this page (a new tab,
// a middle click, a notification). Browsers refuse window.close() for a tab with history, and
// then Turbo simply shows the result as usual.
export default class extends Controller {
  closeOnSuccess(event) {
    if (event.detail.success) window.close()
  }
}
