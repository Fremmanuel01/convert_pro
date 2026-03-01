import { Controller } from "@hotwired/stimulus"
import { jsPDF } from "jspdf"
import { PDFDocument } from "pdf-lib"
import { zipSync } from "fflate"

export default class extends Controller {
    static values = {
        toolId: String,
        acceptsMultiple: Boolean
    }
    static targets = ["form", "fileInput", "submitButton", "passwordInput"]

    process(event) {
        const clientSideTools = ['images_to_pdf', 'merge_pdf', 'split_pdf', 'protect_pdf', 'unlock_pdf']

        if (clientSideTools.includes(this.toolIdValue)) {
            event.preventDefault()

            switch (this.toolIdValue) {
                case 'images_to_pdf':
                    this.processImagesToPdf()
                    break
                case 'merge_pdf':
                    this.processMergePdf()
                    break
                case 'split_pdf':
                    this.processSplitPdf()
                    break
                case 'protect_pdf':
                    this.processProtectPdf()
                    break
                case 'unlock_pdf':
                    this.processUnlockPdf()
                    break
            }
        }
    }

    async processImagesToPdf() {
        const files = this.fileInputTarget.files
        if (files.length === 0) return

        this.setProcessing(true)

        try {
            const pdf = new jsPDF()
            for (let i = 0; i < files.length; i++) {
                const file = files[i]
                const imageData = await this.readFileAsDataURL(file)
                if (i > 0) pdf.addPage()
                const imgProps = pdf.getImageProperties(imageData)
                const pdfWidth = pdf.internal.pageSize.getWidth()
                const pdfHeight = (imgProps.height * pdfWidth) / imgProps.width
                pdf.addImage(imageData, 'auto', 0, 0, pdfWidth, pdfHeight)
            }
            pdf.save(`images_to_pdf_${Date.now()}.pdf`)
            this.formTarget.reset()
            this.resetUI()
        } catch (error) {
            console.error("PDF Generation Error:", error)
            alert("Failed to generate PDF. Please try again.")
        } finally {
            this.setProcessing(false)
        }
    }

    async processMergePdf() {
        const files = this.fileInputTarget.files
        if (files.length < 2) {
            alert("Please select at least 2 PDF files to merge.")
            return
        }
        this.setProcessing(true)
        try {
            const mergedPdf = await PDFDocument.create()
            for (const file of files) {
                const fileBytes = await this.readFileAsArrayBuffer(file)
                const pdf = await PDFDocument.load(fileBytes)
                const copiedPages = await mergedPdf.copyPages(pdf, pdf.getPageIndices())
                copiedPages.forEach((page) => mergedPdf.addPage(page))
            }
            const pdfBytes = await mergedPdf.save()
            this.downloadBlob(new Blob([pdfBytes], { type: 'application/pdf' }), `merged_${Date.now()}.pdf`)
            this.formTarget.reset()
            this.resetUI()
        } catch (error) {
            console.error("Merge Error:", error)
            alert("Failed to merge PDFs. Are you sure they aren't password protected?")
        } finally {
            this.setProcessing(false)
        }
    }

    async processSplitPdf() {
        const files = this.fileInputTarget.files
        if (files.length === 0) return
        this.setProcessing(true)
        try {
            const file = files[0]
            const fileBytes = await this.readFileAsArrayBuffer(file)
            const pdf = await PDFDocument.load(fileBytes)
            const pageCount = pdf.getPageCount()
            const zipData = {}
            for (let i = 0; i < pageCount; i++) {
                const newPdf = await PDFDocument.create()
                const [copiedPage] = await newPdf.copyPages(pdf, [i])
                newPdf.addPage(copiedPage)
                const newPdfBytes = await newPdf.save()
                zipData[`page_${i + 1}.pdf`] = new Uint8Array(newPdfBytes)
            }
            const zipped = zipSync(zipData)
            this.downloadBlob(new Blob([zipped], { type: 'application/zip' }), `split_${Date.now()}.zip`)
            this.formTarget.reset()
            this.resetUI()
        } catch (error) {
            console.error("Split Error:", error)
            alert("Failed to split PDF. Please try again.")
        } finally {
            this.setProcessing(false)
        }
    }

    async processProtectPdf() {
        const files = this.fileInputTarget.files
        const password = this.passwordInputTarget.value
        if (files.length === 0 || !password) {
            alert("Please select a file and enter a password.")
            return
        }
        this.setProcessing(true)
        try {
            const file = files[0]
            const fileBytes = await this.readFileAsArrayBuffer(file)
            const pdf = await PDFDocument.load(fileBytes)
            const encryptedBytes = await pdf.save({
                userPassword: password,
                ownerPassword: password,
                permissions: {
                    printing: 'highResolution',
                    modifying: true,
                    copying: true,
                    annotating: true,
                    fillingForms: true,
                    contentAccessibility: true,
                    documentAssembly: true,
                }
            })
            this.downloadBlob(new Blob([encryptedBytes], { type: 'application/pdf' }), `protected_${Date.now()}.pdf`)
            this.formTarget.reset()
            this.resetUI()
        } catch (error) {
            console.error("Protect Error:", error)
            alert("Failed to protect PDF.")
        } finally {
            this.setProcessing(false)
        }
    }

    async processUnlockPdf() {
        const files = this.fileInputTarget.files
        const password = this.passwordInputTarget.value
        if (files.length === 0 || !password) {
            alert("Please select a file and enter the password.")
            return
        }
        this.setProcessing(true)
        try {
            const file = files[0]
            const fileBytes = await this.readFileAsArrayBuffer(file)
            const pdf = await PDFDocument.load(fileBytes, { password })
            const decryptedBytes = await pdf.save()
            this.downloadBlob(new Blob([decryptedBytes], { type: 'application/pdf' }), `unlocked_${Date.now()}.pdf`)
            this.formTarget.reset()
            this.resetUI()
        } catch (error) {
            console.error("Unlock Error:", error)
            alert("Failed to unlock PDF. Is the password correct?")
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

    readFileAsArrayBuffer(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader()
            reader.onload = () => resolve(reader.result)
            reader.onerror = reject
            reader.readAsArrayBuffer(file)
        })
    }

    downloadBlob(blob, filename) {
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = filename
        document.body.appendChild(a)
        a.click()
        setTimeout(() => {
            document.body.removeChild(a)
            URL.revokeObjectURL(url)
        }, 0)
    }

    resetUI() {
        const fileNameDisplay = document.getElementById('file-name-display')
        if (fileNameDisplay) fileNameDisplay.classList.add('hidden')
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
                    Processing...
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
