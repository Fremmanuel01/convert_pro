import { Controller } from "@hotwired/stimulus"

// Restrained number count-up for a single stat (e.g. tool count). Motion that
// acknowledges a value, not decoration. Respects reduced-motion.
export default class extends Controller {
  static values = { to: Number, duration: { type: Number, default: 900 } }

  connect() {
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    if (reduce || !this.toValue) {
      this.element.textContent = String(this.toValue || this.element.textContent)
      return
    }
    const start = performance.now()
    const from = 0
    const step = (now) => {
      const p = Math.min((now - start) / this.durationValue, 1)
      const eased = 1 - Math.pow(1 - p, 3)
      this.element.textContent = String(Math.round(from + (this.toValue - from) * eased))
      if (p < 1) requestAnimationFrame(step)
    }
    requestAnimationFrame(step)
  }
}
