import { Controller } from "@hotwired/stimulus"

// Reusable, accessible upload surface.
//
// Two modes:
//  - "recommend" (homepage): identify the dropped file's type from the tool
//    registry (passed as JSON) and show only the tools that actually accept it.
//    No upload happens here; picking a tool navigates to that tool's page.
//  - default: a drop/pick/preview surface other tool forms can adopt.
//
// This is discovery UX only. It NEVER implies browser validation replaces the
// authoritative server-side validation performed on submit.
export default class extends Controller {
  static targets = ["input", "dropzone", "preview", "filename", "filesize", "results", "empty", "prompt"]
  static values = {
    tools: { type: Array, default: [] }, // [{id,name,icon,category,accepts:[mime...],exts:[...]}]
    mode: { type: String, default: "default" },
    eventsUrl: { type: String, default: "" }
  }

  connect() {
    this.dragging = false
  }

  open() { this.inputTarget.click() }

  onKeydown(event) {
    if (event.key === "Enter" || event.key === " ") {
      event.preventDefault()
      this.open()
    }
  }

  dragover(event) {
    event.preventDefault()
    if (!this.dragging) {
      this.dragging = true
      this.element.classList.add("uploader--dragover")
    }
  }

  dragleave(event) {
    event.preventDefault()
    this.dragging = false
    this.element.classList.remove("uploader--dragover")
  }

  drop(event) {
    event.preventDefault()
    this.dragging = false
    this.element.classList.remove("uploader--dragover")
    const files = event.dataTransfer?.files
    if (files && files.length) {
      if (this.hasInputTarget) this.inputTarget.files = files
      this.handleFile(files[0])
    }
  }

  change() {
    const file = this.inputTarget.files?.[0]
    if (file) this.handleFile(file)
  }

  remove() {
    if (this.hasInputTarget) this.inputTarget.value = ""
    if (this.hasPreviewTarget) this.previewTarget.hidden = true
    if (this.hasPromptTarget) this.promptTarget.hidden = false
    if (this.hasResultsTarget) this.resultsTarget.innerHTML = ""
  }

  handleFile(file) {
    if (this.hasFilenameTarget) this.filenameTarget.textContent = file.name
    if (this.hasFilesizeTarget) this.filesizeTarget.textContent = this.humanSize(file.size)
    if (this.hasPreviewTarget) this.previewTarget.hidden = false
    if (this.hasPromptTarget) this.promptTarget.hidden = true

    if (this.modeValue === "recommend") this.recommend(file)
  }

  recommend(file) {
    if (!this.hasResultsTarget) return
    const ext = (file.name.split(".").pop() || "").toLowerCase()
    const type = (file.type || "").toLowerCase()

    const matches = this.toolsValue.filter((t) => {
      const accepts = (t.accepts || []).map((s) => s.toLowerCase())
      const exts = (t.exts || []).map((s) => s.toLowerCase())
      return (type && accepts.includes(type)) || exts.includes(ext)
    })

    if (matches.length === 0) {
      this.resultsTarget.innerHTML =
        `<p class="uploader-empty">We don't have a tool for <strong>.${this.escape(ext)}</strong> files yet. Browse all tools below.</p>`
      return
    }

    this.reportFileSelected(ext)

    this.resultsTarget.innerHTML = matches
      .map(
        (t) => `
        <a href="/tools/${encodeURIComponent(t.id)}?from=home" class="uploader-action">
          <span class="material-symbols-outlined uploader-action__icon">${this.escape(t.icon)}</span>
          <span class="uploader-action__body">
            <span class="uploader-action__name">${this.escape(t.name)}</span>
            <span class="uploader-action__cat">${this.escape(t.category)}</span>
          </span>
          <span class="material-symbols-outlined uploader-action__go">arrow_forward</span>
        </a>`
      )
      .join("")
  }

  // Best-effort funnel event. No filename/contents — only the extension family.
  reportFileSelected(ext) {
    if (!this.hasEventsUrlValue || !this.eventsUrlValue) return
    const csrf = document.querySelector('meta[name="csrf-token"]')?.content
    fetch(this.eventsUrlValue, {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": csrf },
      body: JSON.stringify({ name: "file_selected", ext })
    }).catch(() => {})
  }

  humanSize(bytes) {
    if (!bytes) return ""
    const units = ["B", "KB", "MB", "GB"]
    let i = 0
    let n = bytes
    while (n >= 1024 && i < units.length - 1) { n /= 1024; i++ }
    return `${n.toFixed(n < 10 && i > 0 ? 1 : 0)} ${units[i]}`
  }

  escape(s) {
    return String(s ?? "").replace(/[&<>"']/g, (c) =>
      ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c])
    )
  }
}
