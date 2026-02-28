module Tools
  class DocxToPdf < BaseTool
    SOFFICE_BIN = ENV.fetch("SOFFICE_BIN", Rails.env.production? ? "soffice" : "/Applications/LibreOffice.app/Contents/MacOS/soffice")

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
        "--headless",
        "--convert-to", "pdf:writer_pdf_Export",
        "--outdir", @tmp_dir,
        input_path
      ].shelljoin

      unless system(command)
        raise ExecutionError, "LibreOffice conversion failed."
      end
      
      unless File.exist?(expected_output_path)
        raise ExecutionError, "LibreOffice failed to generate a PDF output."
      end

      expected_output_path
    end
  end
end
