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
      profile_dir = tmp_path("lo_profile_#{Time.now.to_f}")

      command = [
        SOFFICE_BIN,
        "-env:UserInstallation=file://#{profile_dir}",
        "-env:JFW_PLUGIN_DO_NOT_CHECK_ACCESSIBILITY=1",
        "--nofirststartwizard",
        "--headless",
        "--convert-to", "docx:MS Word 2007 XML",
        "--infilter=writer_pdf_import",
        "--outdir", @tmp_dir,
        input_path
      ]

      require 'open3'
      stdout, stderr, status = Open3.capture3(*command)

      Rails.logger.info("PdfToDocx stdout: #{stdout}") if stdout.present?
      Rails.logger.info("PdfToDocx stderr: #{stderr}") if stderr.present?

      unless status.success?
        raise ExecutionError, "LibreOffice conversion failed: #{stderr.strip.presence || stdout.strip}"
      end

      # LibreOffice may produce a slightly different filename — scan the dir
      docx_files = Dir.glob(File.join(@tmp_dir, "*.docx")).sort_by { |f| File.mtime(f) }.reverse
      raise ExecutionError, "LibreOffice ran but produced no DOCX output. The PDF may be image-only or password-protected — try running OCR first." if docx_files.empty?

      docx_files.first
    end
  end
end
