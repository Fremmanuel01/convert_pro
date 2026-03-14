module Tools
  class DocxToPdf < BaseTool
    def self.find_binary
      return "/Applications/LibreOffice.app/Contents/MacOS/soffice" unless Rails.env.production?
      
      # In Ubuntu, the binary might be installed as either `libreoffice` or `soffice`
      ['libreoffice', 'soffice'].find { |bin| system("which #{bin} > /dev/null 2>&1") } || "soffice"
    end

    SOFFICE_BIN = ENV.fetch("SOFFICE_BIN", find_binary)

    protected

    def process(input_paths)
      if input_paths.size > 1
        raise ExecutionError, "Word to PDF only accepts a single file."
      end

      input_path = input_paths.first
      output_filename = File.basename(input_path, ".*") + ".pdf"
      expected_output_path = tmp_path(output_filename)

      # LibreOffice headless command with strict mapping and isolated user profiles
      # The UserInstallation flag prevents concurrent conversions from clashing over the same LibreOffice profile lock
      profile_dir = tmp_path("lo_profile_#{Time.now.to_f}")
      
      command = [
        SOFFICE_BIN,
        "-env:UserInstallation=file://#{profile_dir}",
        "-env:JFW_PLUGIN_DO_NOT_CHECK_ACCESSIBILITY=1",
        "--nofirststartwizard",
        "--headless",
        "--convert-to", "pdf:writer_pdf_Export",
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

      apply_page_layout!(expected_output_path)
      expected_output_path
    end

    private

    def apply_page_layout!(pdf_path)
      opts        = @conversion.try(:options) || {}
      page_size   = opts['page_size'].presence
      orientation = opts['page_orientation'].presence

      return unless page_size || orientation

      gs_size = { 'A4' => 'a4', 'A3' => 'a3', 'Letter' => 'letter', 'Legal' => 'legal' }[page_size] || 'a4'
      resized = pdf_path + '_resized.pdf'

      # Landscape: swap width/height via custom page size
      extra = if orientation == 'landscape'
        dims = { 'a4' => '842 595', 'a3' => '1191 842', 'letter' => '792 612', 'legal' => '1008 612' }[gs_size] || '842 595'
        ["-dDEVICEWIDTHPOINTS=#{dims.split.first}", "-dDEVICEHEIGHTPOINTS=#{dims.split.last}"]
      else
        ["-sPAPERSIZE=#{gs_size}"]
      end

      command = [
        'gs', '-sDEVICE=pdfwrite', '-dNOPAUSE', '-dBATCH', '-dQUIET',
        '-dFIXEDMEDIA', '-dPDFFitPage',
        *extra,
        "-sOutputFile=#{resized}",
        pdf_path
      ]

      require 'open3'
      _o, _e, status = Open3.capture3(*command)
      FileUtils.mv(resized, pdf_path) if status.success? && File.exist?(resized)
    end
  end
end
