import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    toggle() {
        document.documentElement.classList.toggle("dark")
        if (document.documentElement.classList.contains("dark")) {
            localStorage.setItem("theme", "dark")
        } else {
            localStorage.setItem("theme", "light")
        }
    }
}
