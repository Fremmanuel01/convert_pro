import { Controller } from "@hotwired/stimulus"
import { jsPDF } from "jspdf"
import { PDFDocument } from "pdf-lib"
import { zipSync } from "fflate"
import * as pdfjsDist from "pdfjs-dist"
import heic2any from "heic2any"

// Configure PDF.js worker
pdfjsDist.GlobalWorkerOptions.workerSrc = `https://esm.run/pdfjs-dist@4.0.379/build/pdf.worker.mjs`

export default class extends Controller {
    static values = {
        toolId: String,
        acceptsMultiple: Boolean,
        logUrl: String
    }
    static targets = ["form", "fileInput", "submitButton", "passwordInput"]

    process(event) {
        const clientSideTools = [
            'images_to_pdf', 'merge_pdf', 'split_pdf', 'protect_pdf', 'unlock_pdf',
            'pdf_to_images', 'heic_to_jpg', 'heic_to_png', 'webp_to_jpg', 'webp_to_png'
        ]

        if (clientSideTools.includes(this.toolIdValue)) {
            event.preventDefault()

            switch (this.toolIdValue) {
                case 'images_to_pdf': this.processImagesToPdf(); break
                case 'merge_pdf': this.processMergePdf(); break
                case 'split_pdf': this.processSplitPdf(); break
                case 'protect_pdf': this.processProtectPdf(); break
                case 'unlock_pdf': this.processUnlockPdf(); break
                case 'pdf_to_images': this.processPdfToImages(); break
                case 'heic_to_jpg': this.processHeicTo('image/jpeg'); break
                case 'heic_to_png': this.processHeicTo('image/png'); break
                case 'webp_to_jpg': this.processWebpTo('image/jpeg'); break
                case 'webp_to_png': this.processWebpTo('image/png'); break
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
            this.reportActivity()
            this.formTarget.reset()
            this.resetUI()
        } catch (error) {
            console.error(error)
            alert("Failed to generate PDF.")
        } finally {
            this.setProcessing(false)
        }
    }

    async processMergePdf() {
        const files = this.fileInputTarget.files
        if (files.length < 2) {
            alert("Please select at least 2 PDF files.")
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
            this.reportActivity()
            this.formTarget.reset()
            this.resetUI()
        } catch (error) {
            console.error(error)
            alert("Failed to merge PDFs.")
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
            const zipData = {}
            for (let i = 0; i < pdf.getPageCount(); i++) {
                const newPdf = await PDFDocument.create()
                const [copiedPage] = await newPdf.copyPages(pdf, [i])
                newPdf.addPage(copiedPage)
                const newPdfBytes = await newPdf.save()
                zipData[`page_${i + 1}.pdf`] = new Uint8Array(newPdfBytes)
            }
            const zipped = zipSync(zipData)
            this.downloadBlob(new Blob([zipped], { type: 'application/zip' }), `split_${Date.now()}.zip`)
            this.reportActivity()
            this.formTarget.reset()
            this.resetUI()
        } catch (error) {
            console.error(error)
            alert("Failed to split PDF.")
        } finally {
            this.setProcessing(false)
        }
    }

    async processProtectPdf() {
        const files = this.fileInputTarget.files
        const password = this.passwordInputTarget.value
        if (files.length === 0 || !password) return
        this.setProcessing(true)
        try {
            const fileBytes = await this.readFileAsArrayBuffer(files[0])
            const pdf = await PDFDocument.load(fileBytes)
            const encryptedBytes = await pdf.save({
                userPassword: password,
                ownerPassword: password
            })
            this.downloadBlob(new Blob([encryptedBytes], { type: 'application/pdf' }), `protected_${Date.now()}.pdf`)
            this.reportActivity()
            this.formTarget.reset()
            this.resetUI()
        } catch (error) {
            console.error(error)
            alert("Failed to protect PDF.")
        } finally {
            this.setProcessing(false)
        }
    }

    async processUnlockPdf() {
        const files = this.fileInputTarget.files
        const password = this.passwordInputTarget.value
        if (files.length === 0 || !password) return
        this.setProcessing(true)
        try {
            const fileBytes = await this.readFileAsArrayBuffer(files[0])
            const pdf = await PDFDocument.load(fileBytes, { password })
            const decryptedBytes = await pdf.save()
            this.downloadBlob(new Blob([decryptedBytes], { type: 'application/pdf' }), `unlocked_${Date.now()}.pdf`)
            this.reportActivity()
            this.formTarget.reset()
            this.resetUI()
        } catch (error) {
            console.error(error)
            alert("Failed to unlock PDF. Wrong password?")
        } finally {
            this.setProcessing(false)
        }
    }

    async processPdfToImages() {
        const files = this.fileInputTarget.files
        if (files.length === 0) return
        this.setProcessing(true)
        try {
            const file = files[0]
            const fileBytes = await this.readFileAsArrayBuffer(file)
            const loadingTask = pdfjsDist.getDocument({ data: fileBytes })
            const pdf = await loadingTask.promise
            const zipData = {}
            for (let i = 1; i <= pdf.numPages; i++) {
                const page = await pdf.getPage(i)
                const viewport = page.getViewport({ scale: 2.0 })
                const canvas = document.createElement('canvas')
                const context = canvas.getContext('2d')
                canvas.height = viewport.height
                canvas.width = viewport.width
                await page.render({ canvasContext: context, viewport: viewport }).promise
                const blob = await new Promise(resolve => canvas.toBlob(resolve, 'image/jpeg', 0.9))
                zipData[`page_${i}.jpg`] = new Uint8Array(await blob.arrayBuffer())
            }
            const zipped = zipSync(zipData)
            this.downloadBlob(new Blob([zipped], { type: 'application/zip' }), `images_${Date.now()}.zip`)
            this.reportActivity()
            this.formTarget.reset()
            this.resetUI()
        } catch (error) {
            console.error(error)
            alert("Failed to extract images from PDF.")
        } finally {
            this.setProcessing(false)
        }
    }

    async processHeicTo(type) {
        const files = this.fileInputTarget.files
        if (files.length === 0) return
        this.setProcessing(true)
        try {
            const blob = await heic2any({ blob: files[0], toType: type })
            const extension = type === 'image/jpeg' ? 'jpg' : 'png'
            this.downloadBlob(blob, `converted_${Date.now()}.${extension}`)
            this.reportActivity()
            this.formTarget.reset()
            this.resetUI()
        } catch (error) {
            console.error(error)
            alert("Failed to convert HEIC.")
        } finally {
            this.setProcessing(false)
        }
    }

    async processWebpTo(type) {
        const files = this.fileInputTarget.files
        if (files.length === 0) return
        this.setProcessing(true)
        try {
            const img = new Image()
            img.src = await this.readFileAsDataURL(files[0])
            await new Promise(resolve => img.onload = resolve)
            const canvas = document.createElement('canvas')
            canvas.width = img.width
            canvas.height = img.height
            canvas.getContext('2d').drawImage(img, 0, 0)
            const blob = await new Promise(resolve => canvas.toBlob(resolve, type, 0.9))
            const extension = type === 'image/jpeg' ? 'jpg' : 'png'
            this.downloadBlob(blob, `converted_${Date.now()}.${extension}`)
            this.reportActivity()
            this.formTarget.reset()
            this.resetUI()
        } catch (error) {
            console.error(error)
            alert("Failed to convert WEBP.")
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

    reportActivity() {
        const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
        if (!this.logUrlValue) return

        fetch(this.logUrlValue, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrfToken },
            body: JSON.stringify({ tool_id: this.toolIdValue })
        }).catch(e => console.error(e))
    }

    resetUI() {
        const el = document.getElementById('file-name-display')
        if (el) el.classList.add('hidden')
    }

    setProcessing(isProcessing) {
        if (!this.hasSubmitButtonTarget) return
        if (isProcessing) {
            this.submitButtonTarget.disabled = true
            this.submitButtonOriginalContent = this.submitButtonTarget.innerHTML
            this.submitButtonTarget.innerHTML = `<svg class="animate-spin -ml-1 mr-3 h-5 w-5 text-white inline flex-shrink-0" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg> Processing...`
        } else {
            this.submitButtonTarget.disabled = false
            this.submitButtonTarget.innerHTML = this.submitButtonOriginalContent || 'Process Document'
        }
    }
}
