import { Controller } from "@hotwired/stimulus"
import { jsPDF } from "jspdf"

export default class extends Controller {
    static values = {
        toolId: String,
        acceptsMultiple: Boolean
    }
    static targets = ["form", "fileInput", "submitButton"]

    process(event) {
        if (this.toolIdValue === 'images_to_pdf') {
            event.preventDefault()
            this.processImagesToPdf()
        }
        // Other client-side tools can be added here
    }

    async processImagesToPdf() {
        const files = this.fileInputTarget.files
        if (files.length === 0) return

        this.setProcessing(true)

        try {
            // Default to A4, portrait
            const pdf = new jsPDF()

            for (let i = 0; i < files.length; i++) {
                const file = files[i]
                const imageData = await this.readFileAsDataURL(file)

                if (i > 0) {
                    pdf.addPage()
                }

                const imgProps = pdf.getImageProperties(imageData)
                const pdfWidth = pdf.internal.pageSize.getWidth()
                const pdfHeight = (imgProps.height * pdfWidth) / imgProps.width

                // If the image is taller than the page, we might want to scale it or just center it.
                // For now, simple scaling to width.
                pdf.addImage(imageData, 'auto', 0, 0, pdfWidth, pdfHeight)
            }

            pdf.save(`images_to_pdf_${Date.now()}.pdf`)

            // Reset the form after success
            this.formTarget.reset()
            const fileNameDisplay = document.getElementById('file-name-display')
            if (fileNameDisplay) fileNameDisplay.classList.add('hidden')

        } catch (error) {
            console.error("PDF Generation Error:", error)
            alert("Failed to generate PDF. Please try again.")
        } finally {
            this.setProcessing(false)
        }
    }

    readFileAsDataURL(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader()
            reader.onload = () => resolve(reader.result)
            reader.onerror = reject
            reader.readAsDataURL(file)
        })
    }

    setProcessing(isProcessing) {
        if (isProcessing) {
            if (this.hasSubmitButtonTarget) {
                this.submitButtonTarget.disabled = true
                this.submitButtonOriginalContent = this.submitButtonTarget.innerHTML
                this.submitButtonTarget.innerHTML = `
          <svg class="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
          Generating PDF...
        `
            }
        } else {
            if (this.hasSubmitButtonTarget) {
                this.submitButtonTarget.disabled = false
                this.submitButtonTarget.innerHTML = this.submitButtonOriginalContent || 'Process Document'
            }
        }
    }
}
