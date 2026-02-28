// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import { setupFirebaseAuth } from "firebase_auth"
import "controllers"

// Initialize Firebase Auth if the config is present securely
const firebaseConfigMeta = document.querySelector('meta[name="firebase-config"]')
if (firebaseConfigMeta) {
  const firebaseConfig = JSON.parse(firebaseConfigMeta.content)
  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
  setupFirebaseAuth(firebaseConfig, csrfToken)
}

document.addEventListener("turbo:load", () => {
  // Theme Toggle
  const themeToggle = document.getElementById("theme-toggle")
  if (themeToggle) {
    themeToggle.addEventListener("click", () => {
      document.documentElement.classList.toggle("dark")
      if (document.documentElement.classList.contains("dark")) {
        localStorage.setItem("theme", "dark")
      } else {
        localStorage.setItem("theme", "light")
      }
    })
  }

  // Profile Dropdown
  const profileToggle = document.getElementById("profile-toggle")
  const profileDropdown = document.getElementById("profile-dropdown")

  if (profileToggle && profileDropdown) {
    profileToggle.addEventListener("click", (e) => {
      e.stopPropagation()
      profileDropdown.classList.toggle("opacity-0")
      profileDropdown.classList.toggle("invisible")
      profileDropdown.classList.toggle("translate-y-2")
    })

    // Close dropdown when clicking outside
    document.addEventListener("click", (e) => {
      if (!profileDropdown.contains(e.target) && !profileToggle.contains(e.target)) {
        profileDropdown.classList.add("opacity-0", "invisible", "translate-y-2")
      }
    })
  }

})
