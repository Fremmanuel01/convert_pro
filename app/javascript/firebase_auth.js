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

            // 3. Submit a hidden form so the browser handles the session cookie
            //    naturally via a full page POST + redirect (fetch breaks cookie persistence)
            const form = document.createElement('form')
            form.method = 'POST'
            form.action = '/users/auth/firebase'

            const fields = { token: idToken, authenticity_token: csrfToken }
            Object.entries(fields).forEach(([name, value]) => {
                const input = document.createElement('input')
                input.type = 'hidden'
                input.name = name
                input.value = value
                form.appendChild(input)
            })

            document.body.appendChild(form)
            form.submit()

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
