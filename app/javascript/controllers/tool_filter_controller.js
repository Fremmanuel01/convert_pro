import { Controller } from "@hotwired/stimulus"

// Instant client-side search + category filtering for the tools page.
export default class extends Controller {
  static targets = ["search", "tab", "group", "empty"]

  connect() {
    this.activeCategory = "all"
    this.query = ""
    this.apply()
  }

  search() {
    this.query = this.searchTarget.value.trim().toLowerCase()
    this.apply()
  }

  filter(event) {
    this.activeCategory = event.currentTarget.dataset.filter
    this.tabTargets.forEach((t) => {
      const active = t === event.currentTarget
      t.classList.toggle("is-active", active)
      t.setAttribute("aria-selected", active ? "true" : "false")
    })
    this.apply()
  }

  apply() {
    let anyVisible = false

    this.groupTargets.forEach((group) => {
      const inCategory = this.activeCategory === "all" || group.dataset.group === this.activeCategory
      let groupHasVisible = false

      group.querySelectorAll(".tool-card").forEach((card) => {
        const matchesQuery = !this.query || (card.dataset.name || "").includes(this.query)
        const show = inCategory && matchesQuery
        card.hidden = !show
        if (show) groupHasVisible = true
      })

      group.hidden = !groupHasVisible
      if (groupHasVisible) anyVisible = true
    })

    if (this.hasEmptyTarget) this.emptyTarget.hidden = anyVisible
  }
}
