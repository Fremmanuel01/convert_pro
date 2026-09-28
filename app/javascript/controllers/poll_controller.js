import { Controller } from "@hotwired/stimulus"

// Polls a status endpoint and swaps this element in place until the server
// marks it terminal (completed/failed). No Turbo dependency: it fetches the
// status HTML fragment and replaces its own outerHTML, so Stimulus disconnects
// the old controller and connects the fresh one (which re-reads `active` and
// stops if terminal). Ownership is enforced server-side on every poll.
export default class extends Controller {
  static values = {
    active: Boolean,
    url: String,
    interval: { type: Number, default: 2500 },
    autoDownload: String
  }

  connect() {
    if (this.hasAutoDownloadValue && this.autoDownloadValue) {
      this.triggerDownload(this.autoDownloadValue)
    }
    if (this.activeValue && this.hasUrlValue) {
      this.schedule()
    }
  }

  disconnect() {
    if (this.timer) clearTimeout(this.timer)
  }

  schedule() {
    this.timer = setTimeout(() => this.poll(), this.intervalValue)
  }

  async poll() {
    try {
      const res = await fetch(this.urlValue, { headers: { Accept: "text/html" } })
      if (res.ok) {
        const html = await res.text()
        this.element.outerHTML = html // Stimulus reconnects the replacement
        return
      }
    } catch (_e) {
      // transient network error — fall through and retry
    }
    this.schedule()
  }

  triggerDownload(url) {
    const a = document.createElement("a")
    a.href = url
    a.rel = "noopener"
    document.body.appendChild(a)
    a.click()
    a.remove()
  }
}
