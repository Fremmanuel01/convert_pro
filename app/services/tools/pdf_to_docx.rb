module Tools
  class PdfToDocx < BaseTool
    def self.find_binary
      return "/Applications/LibreOffice.app/Contents/MacOS/soffice" unless Rails.env.production?
      
      # In Ubuntu, the binary might be installed as either `libreoffice` or `soffice`
      ['libreoffice', 'soffice'].find { |bin| system("which #{bin} > /dev/null 2>&1") } || "soffice"
    end

    SOFFICE_BIN = ENV.fetch("SOFFICE_BIN", find_binary)

    protected

    def process(input_paths)
      if input_paths.size > 1
        raise ExecutionError, "PDF to Word only accepts a single file."
      end

      input_path = input_paths.first
      output_filename = File.basename(input_path, ".*") + ".docx"
      expected_output_path = tmp_path(output_filename)

      # LibreOffice headless command with isolated user profiles
      profile_dir = tmp_path("lo_profile")
      Dir.mkdir(profile_dir) unless Dir.exist?(profile_dir)
      
      command = [
        SOFFICE_BIN,
        "-env:UserInstallation=file://#{profile_dir}",
        "--headless",
        "--convert-to", "docx",
        "--outdir", @tmp_dir,
        input_path
      ].shelljoin
      
      require 'open3'
      stdout, stderr, status = Open3.capture3(command)

      unless status.success?
        raise ExecutionError, "LibreOffice conversion failed. Exit code: #{status.exitstatus}. Error: #{stderr.strip.presence || stdout.strip}"
      end
      
      unless File.exist?(expected_output_path)
        # If the file doesn't exist, log what happened for debugging
        Rails.logger.error("LibreOffice success but NO FILE found. STDOUT: #{stdout} STDERR: #{stderr}")
        raise ExecutionError, "LibreOffice failed to generate a DOCX output. (Command reported success but file missing)"
      end

      expected_output_path
    end

  end
end
