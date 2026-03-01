# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

pin "firebase_auth", to: "firebase_auth.js"
pin "firebase/app", to: "https://www.gstatic.com/firebasejs/10.10.0/firebase-app.js"
pin "firebase/auth", to: "https://www.gstatic.com/firebasejs/10.10.0/firebase-auth.js"

pin "jspdf", to: "https://esm.run/jspdf@2.5.1"
pin "fflate", to: "https://esm.run/fflate@0.8.2"
pin "pdf-lib", to: "https://esm.run/pdf-lib@1.17.1"
