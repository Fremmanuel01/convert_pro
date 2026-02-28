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


