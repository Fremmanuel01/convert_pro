module Tools
  class CompressPdf < BaseTool
    protected

    def process(input_paths)
      if input_paths.size > 1
        raise ExecutionError, "Compress PDF only accepts a single file."
      end

      input_path = input_paths.first
      output_path = tmp_path("compressed_output.pdf")

      # Ghostscript command for screen-level compression
      command = [
        "gs",
        "-sDEVICE=pdfwrite",
        "-dCompatibilityLevel=1.4",
        "-dPDFSETTINGS=/ebook", # 150dpi baseline (better than /screen 72dpi) for legible text
        "-dNOPAUSE",
        "-dQUIET",
        "-dBATCH",
        "-sOutputFile=#{output_path}",
        input_path
      ]

      unless system(*command)
        raise ExecutionError, "Ghostscript compression failed. Could not process file."
      end
      
      unless File.exist?(output_path)
        raise ExecutionError, "Output file was not generated."
      end

      output_path
    end
  end
end
