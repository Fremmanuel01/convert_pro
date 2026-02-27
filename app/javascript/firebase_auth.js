import { initializeApp } from "firebase/app"
import { getAuth, signInWithPopup, GoogleAuthProvider } from "firebase/auth"

// Initialize Firebase using environment variables (populated in the view or .env)
const setupFirebaseAuth = (firebaseConfig, csrfToken) => {
    const app = initializeApp(firebaseConfig)
    const auth = getAuth(app)
    const provider = new GoogleAuthProvider()

    const googleBtn = document.getElementById('google-signin-btn')
    const errorAlert = document.getElementById('firebase-auth-error')

    if (!googleBtn) return

    googleBtn.addEventListener('click', async (e) => {
        e.preventDefault()

        // UI Loading state
        const originalText = googleBtn.innerHTML
        googleBtn.innerHTML = '<span class="material-symbols-outlined animate-spin mr-2">refresh</span> Connecting...'
        googleBtn.disabled = true
        if (errorAlert) errorAlert.classList.add('hidden')

        try {
            // 1. Authenticate with Google via Firebase
            const result = await signInWithPopup(auth, provider)

            // 2. Get the secure JWT token
            const idToken = await result.user.getIdToken()

            // 3. Send the token to the Rails backend
            const response = await fetch('/users/auth/firebase', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': csrfToken
                },
                body: JSON.stringify({ token: idToken })
            })

            const data = await response.json()

            if (response.ok && data.success) {
                // Successfully authenticated & bridged to Devise session!
                window.location.href = data.redirect_url || '/'
            } else {
                throw new Error(data.error || "Failed to authenticate with server")
            }
        } catch (error) {
            console.error("Firebase Auth Error:", error)

            // UI Error state
            if (errorAlert) {
                errorAlert.textContent = `Authentication failed: ${error.message}`
                errorAlert.classList.remove('hidden')
            }

            googleBtn.innerHTML = originalText
            googleBtn.disabled = false
        }
    })
}

export { setupFirebaseAuth }
