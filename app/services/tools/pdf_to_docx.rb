require 'open3'

module Tools
  class PdfToDocx < BaseTool
    def self.find_binary
      return "/Applications/LibreOffice.app/Contents/MacOS/soffice" unless Rails.env.production?
      ['libreoffice', 'soffice'].find { |bin| system("which #{bin} > /dev/null 2>&1") } || "soffice"
    end

    SOFFICE_BIN = ENV.fetch("SOFFICE_BIN", find_binary)

    protected

    def process(input_paths)
      raise ExecutionError, "PDF to Word only accepts a single file." if input_paths.size > 1

      input_path  = input_paths.first

      # If the PDF is image-only (no selectable text), LibreOffice produces no output.
      # Attempt OCR first so the resulting PDF has a text layer that LO can convert.
      working_path = ocr_if_image_only(input_path)

      docx_path = run_libreoffice(working_path)

      # If LibreOffice still produced nothing after OCR, it's truly unprocessable
      if docx_path.nil?
        raise ExecutionError,
          "Could not convert this PDF to Word. It may be heavily encrypted, " \
          "in an unsupported format, or too complex for automatic conversion."
      end

      docx_path
    end

    private

    # Returns the original path unchanged if the PDF already has a text layer,
    # or an OCR-processed copy if it appears to be image-only.
    def ocr_if_image_only(pdf_path)
      return pdf_path unless pdf_appears_image_only?(pdf_path)

      ocrmypdf_bin = `which ocrmypdf 2>/dev/null`.strip
      unless ocrmypdf_bin.present?
        Rails.logger.warn "PdfToDocx: PDF appears image-only but ocrmypdf is not installed."
        return pdf_path
      end

      ocr_output = tmp_path("ocr_output.pdf")
      Rails.logger.info "PdfToDocx: image-only PDF detected — running OCR first"

      _out, _err, status = Open3.capture3(
        *with_timeout(180, ocrmypdf_bin, "--force-ocr", "--quiet", pdf_path, ocr_output)
      )

      File.exist?(ocr_output) && status.success? ? ocr_output : pdf_path
    end

    def pdf_appears_image_only?(pdf_path)
      # Quick heuristic: extract a sample of text; if nothing found, it's likely image-only
      pdftotext = `which pdftotext 2>/dev/null`.strip
      if pdftotext.present?
        text, _err, status = Open3.capture3(pdftotext, "-l", "3", pdf_path, "-")
        return status.success? && text.strip.length < 50
      end
      # Fallback via pdf-reader
      begin
        text = PDF::Reader.new(pdf_path).pages.first(3).map(&:text).join
        text.strip.length < 50
      rescue
        false
      end
    end

    def run_libreoffice(input_path)
      profile_dir = tmp_path("lo_profile_#{Time.now.to_f}")

      command = with_timeout(120,
        SOFFICE_BIN,
        "-env:UserInstallation=file://#{profile_dir}",
        "-env:JFW_PLUGIN_DO_NOT_CHECK_ACCESSIBILITY=1",
        "--nofirststartwizard",
        "--headless",
        "--convert-to", "docx:MS Word 2007 XML",
        "--infilter=writer_pdf_import",
        "--outdir", @tmp_dir,
        input_path
      )

      stdout, stderr, status = Open3.capture3(*command)
      Rails.logger.info("PdfToDocx stdout: #{stdout}") if stdout.present?
      Rails.logger.info("PdfToDocx stderr: #{stderr}") if stderr.present?

      unless status.success?
        raise ExecutionError, "LibreOffice conversion failed: #{stderr.strip.presence || stdout.strip}"
      end

      docx_files = Dir.glob(File.join(@tmp_dir, "*.docx")).sort_by { |f| File.mtime(f) }.reverse
      docx_files.first # nil if nothing produced
    end
  end
end
