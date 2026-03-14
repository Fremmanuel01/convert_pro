require 'open3'

module Tools
  class OcrPdf < BaseTool
    protected

    def process(input_paths)
      if input_paths.size > 1
        raise ExecutionError, "OCR PDF only accepts a single file."
      end

      input_path = input_paths.first
      output_filename = File.basename(input_path, ".*") + "_ocr.pdf"
      output_path = tmp_path(output_filename)

      language = @conversion.try(:options)&.dig('language') || 'eng'

      command = with_timeout(180,
        "ocrmypdf",
        "-l", language,
        "--force-ocr",
        "--optimize", "1",
        input_path, output_path
      )

      _stdout, stderr, status = Open3.capture3(*command)
      unless status.success?
        raise ExecutionError, "OCR failed: #{stderr.strip.presence || 'ensure ocrmypdf is installed and the file is valid'}"
      end

      validate_pdf!(output_path)
      output_path
    end
  end
end
