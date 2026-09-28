import { Controller } from "@hotwired/stimulus"

// Monthly/Yearly toggle on the pricing page: swaps the displayed price, period
// and the checkout link. Prices come from data attributes (BillingPlans source).
export default class extends Controller {
  static targets = ["tab", "price", "period", "cta"]

  select(event) {
    const cycle = event.currentTarget.dataset.cycle
    this.tabTargets.forEach((t) => t.classList.toggle("is-active", t === event.currentTarget))

    if (this.hasPriceTarget) this.priceTarget.textContent = this.priceTarget.dataset[cycle]
    if (this.hasPeriodTarget) this.periodTarget.textContent = cycle === "yearly" ? "/year" : "/month"
    if (this.hasCtaTarget) this.ctaTarget.href = this.ctaTarget.dataset[`${cycle}Url`]
  }
}
