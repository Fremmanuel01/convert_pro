module Tools
  class PdfToDocx < BaseTool
    SOFFICE_BIN = '/Applications/LibreOffice.app/Contents/MacOS/soffice'

    protected

    def process(input_paths)
      if input_paths.size > 1
        raise ExecutionError, "PDF to Word only accepts a single file."
      end

      input_path = input_paths.first
      output_filename = File.basename(input_path, ".*") + ".docx"
      expected_output_path = tmp_path(output_filename)

      # LibreOffice headless parsing via writer filter strategy
      command = [
        SOFFICE_BIN,
        "--infilter=writer_pdf_import",
        "--headless",
        "--convert-to", "docx",
        "--outdir", @tmp_dir,
        input_path
      ].shelljoin

      unless system(command)
        raise ExecutionError, "LibreOffice conversion failed."
      end
      
      unless File.exist?(expected_output_path)
        raise ExecutionError, "LibreOffice failed to generate a DOCX output."
      end

      expected_output_path
    end

  end
end
