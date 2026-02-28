# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

pin "firebase_auth", to: "firebase_auth.js"
pin "firebase/app", to: "https://www.gstatic.com/firebasejs/10.10.0/firebase-app.js"
pin "firebase/auth", to: "https://www.gstatic.com/firebasejs/10.10.0/firebase-auth.js"
