# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

pin "firebase_auth", to: "firebase_auth.js"
pin "firebase/app", to: "https://www.gstatic.com/firebasejs/10.10.0/firebase-app.js"
pin "firebase/auth", to: "https://www.gstatic.com/firebasejs/10.10.0/firebase-auth.js"

pin "jspdf", to: "https://ga.jspm.io/npm:jspdf@2.5.1/dist/jspdf.es.min.js"
pin "fflate", to: "https://ga.jspm.io/npm:fflate@0.8.2/lib/browser.js"
pin "pdf-lib", to: "https://ga.jspm.io/npm:pdf-lib@1.17.1/dist/pdf-lib.min.js"
