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
      quality_map = {
        'screen'   => '/screen',   # 72 dpi — smallest file
        'ebook'    => '/ebook',    # 150 dpi — good balance (default)
        'printer'  => '/printer',  # 300 dpi — high quality
        'prepress' => '/prepress'  # 300 dpi + colour preservation — best quality
      }
      quality = quality_map[@conversion.try(:options)&.dig('quality')] || '/ebook'

      command = [
        "gs",
        "-sDEVICE=pdfwrite",
        "-dCompatibilityLevel=1.4",
        "-dPDFSETTINGS=#{quality}",
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
