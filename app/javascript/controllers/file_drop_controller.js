import { Controller } from "@hotwired/stimulus"

// Focused file-selection UX for tool forms: drag/drop, browse, a clean preview
// list (name + size + type icon), multi-file, and clear. It only manages the
// file input and preview — client-side conversion, quota and submit stay in
// client_tool_controller (composable, single responsibility each).
export default class extends Controller {
  static targets = ["input", "prompt", "preview", "list", "summary"]

  open() { this.inputTarget.click() }

  onKeydown(e) {
    if (e.key === "Enter" || e.key === " ") { e.preventDefault(); this.open() }
  }

  dragover(e) { e.preventDefault(); this.element.classList.add("uploader--dragover") }
  dragleave(e) { e.preventDefault(); this.element.classList.remove("uploader--dragover") }

  drop(e) {
    e.preventDefault()
    this.element.classList.remove("uploader--dragover")
    const files = e.dataTransfer?.files
    if (files && files.length) {
      this.inputTarget.files = files
      this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
    }
  }

  change() {
    const files = Array.from(this.inputTarget.files || [])
    if (!files.length) return this.clear()
    this.render(files)
  }

  clear() {
    this.inputTarget.value = ""
    if (this.hasListTarget) this.listTarget.innerHTML = ""
    if (this.hasPreviewTarget) this.previewTarget.hidden = true
    if (this.hasPromptTarget) this.promptTarget.hidden = false
  }

  render(files) {
    if (this.hasPromptTarget) this.promptTarget.hidden = true
    if (this.hasPreviewTarget) this.previewTarget.hidden = false

    const total = files.reduce((n, f) => n + f.size, 0)
    if (this.hasSummaryTarget) {
      this.summaryTarget.textContent =
        files.length === 1 ? this.humanSize(total) : `${files.length} files · ${this.humanSize(total)}`
    }
    if (this.hasListTarget) {
      this.listTarget.innerHTML = files.map((f) => this.row(f)).join("")
    }
  }

  row(file) {
    const ext = (file.name.split(".").pop() || "").toLowerCase()
    const icon = { pdf: "picture_as_pdf", docx: "description", doc: "description", xlsx: "table_chart",
      xls: "table_chart", pptx: "slideshow", ppt: "slideshow", jpg: "image", jpeg: "image",
      png: "image", heic: "photo_camera", webp: "image" }[ext] || "insert_drive_file"
    return `<div class="flex items-center gap-3 px-4 py-2.5">
      <span class="material-symbols-outlined text-primary text-[22px] shrink-0">${icon}</span>
      <span class="min-w-0 flex-1">
        <span class="block text-sm font-medium text-slate-900 dark:text-white truncate">${this.escape(file.name)}</span>
        <span class="block text-xs text-slate-400">${this.humanSize(file.size)}</span>
      </span>
    </div>`
  }

  humanSize(bytes) {
    if (!bytes) return "0 B"
    const u = ["B", "KB", "MB", "GB"]
    let i = 0, n = bytes
    while (n >= 1024 && i < u.length - 1) { n /= 1024; i++ }
    return `${n.toFixed(n < 10 && i > 0 ? 1 : 0)} ${u[i]}`
  }

  escape(s) {
    return String(s ?? "").replace(/[&<>"']/g, (c) =>
      ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]))
  }
}
