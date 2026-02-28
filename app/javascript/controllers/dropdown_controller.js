import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["menu"]

    toggle(event) {
        if (event) event.stopPropagation()
        this.menuTarget.classList.toggle("opacity-0")
        this.menuTarget.classList.toggle("invisible")
        this.menuTarget.classList.toggle("translate-y-2")
    }

    hide(event) {
        if (!this.element.contains(event.target)) {
            this.menuTarget.classList.add("opacity-0", "invisible", "translate-y-2")
        }
    }
}
