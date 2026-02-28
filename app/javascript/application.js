// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import { setupFirebaseAuth } from "firebase_auth"

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

  // Logged-in App Sidebar (Mobile)
  const sidebarToggle = document.getElementById("sidebar-toggle")
  const appSidebar = document.getElementById("app-sidebar")
  const sidebarOverlay = document.getElementById("sidebar-overlay")

  if (sidebarToggle && appSidebar && sidebarOverlay) {
    const toggleSidebar = () => {
      const isHidden = appSidebar.classList.contains("-translate-x-full")
      if (isHidden) {
        appSidebar.classList.remove("-translate-x-full")
        sidebarOverlay.classList.remove("hidden")
        document.body.style.overflow = "hidden" // Prevent body scroll
      } else {
        appSidebar.classList.add("-translate-x-full")
        sidebarOverlay.classList.add("hidden")
        document.body.style.overflow = "" // Restore scroll
      }
    }

    // Only attach if it hasn't been attached before to avoid duplicates
    // Using onclick for turbo replacement safety
    sidebarToggle.onclick = toggleSidebar
    sidebarOverlay.onclick = toggleSidebar
  }

  // Public Landing Page Navbar (Mobile)
  const mobileMenuButton = document.getElementById("mobile-menu-button")
  const mobileMenu = document.getElementById("mobile-menu")

  if (mobileMenuButton && mobileMenu) {
    mobileMenuButton.onclick = function () {
      const icon = this.querySelector('span')
      if (mobileMenu.classList.contains('hidden')) {
        mobileMenu.classList.remove('hidden')
        mobileMenu.classList.add('flex')
        icon.textContent = 'close'
        document.body.style.overflow = 'hidden'
      } else {
        mobileMenu.classList.add('hidden')
        mobileMenu.classList.remove('flex')
        icon.textContent = 'menu'
        document.body.style.overflow = ''
      }
    }
  }
})
