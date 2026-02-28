import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["menu", "icon"]

    connect() {
        console.log("Mobile menu controller connected!")
    }

    toggle() {
        if (this.menuTarget.classList.contains('hidden')) {
            this.menuTarget.classList.remove('hidden')
            this.menuTarget.classList.add('flex')
            this.iconTarget.textContent = 'close'
            document.body.style.overflow = 'hidden'
        } else {
            this.menuTarget.classList.add('hidden')
            this.menuTarget.classList.remove('flex')
            this.iconTarget.textContent = 'menu'
            document.body.style.overflow = ''
        }
    }
}
