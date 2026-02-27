require 'shellwords'

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

      # Requires `ocrmypdf` installed on the host system
      command = [
        "ocrmypdf",
        "-l", language,
        "--force-ocr", # Forces OCR even if text already exists
        "--optimize", "1",
        input_path, output_path
      ].shelljoin

      unless system(command)
        raise ExecutionError, "OCR Process failed. Ensure ocrmypdf is installed and the file is valid."
      end
      
      unless File.exist?(output_path)
        raise ExecutionError, "Failed to generate OCR output."
      end

      output_path
    end
  end
end
