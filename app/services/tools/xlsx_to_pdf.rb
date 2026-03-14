module Tools
  class XlsxToPdf < BaseTool
    def self.find_binary
      return "/Applications/LibreOffice.app/Contents/MacOS/soffice" unless Rails.env.production?
      ['libreoffice', 'soffice'].find { |bin| system("which #{bin} > /dev/null 2>&1") } || "soffice"
    end

    SOFFICE_BIN = ENV.fetch("SOFFICE_BIN", find_binary)

    protected

    def process(input_paths)
      if input_paths.size > 1
        raise ExecutionError, "Excel to PDF only accepts a single file."
      end

      input_path = input_paths.first
      output_filename = File.basename(input_path, ".*") + ".pdf"
      expected_output_path = tmp_path(output_filename)

      profile_dir = tmp_path("lo_profile_#{Time.now.to_f}")

      command = [
        SOFFICE_BIN,
        "-env:UserInstallation=file://#{profile_dir}",
        "-env:JFW_PLUGIN_DO_NOT_CHECK_ACCESSIBILITY=1",
        "--nofirststartwizard",
        "--headless",
        "--convert-to", "pdf:calc_pdf_Export",
        "--outdir", @tmp_dir,
        input_path
      ]

      require 'open3'
      stdout, stderr, status = Open3.capture3(*command)

      unless status.success?
        raise ExecutionError, "LibreOffice conversion failed. Error: #{stderr.strip.presence || stdout.strip}"
      end

      unless File.exist?(expected_output_path)
        raise ExecutionError, "LibreOffice failed to generate a PDF output."
      end

      expected_output_path
    end
  end
end
