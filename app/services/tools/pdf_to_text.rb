require 'open3'

module Tools
  class PdfToText < BaseTool
    protected

    def process(input_paths)
      if input_paths.size > 1
        raise ExecutionError, "PDF to Text only accepts a single file."
      end

      input_path = input_paths.first
      output_filename = File.basename(input_path, ".*") + ".txt"
      output_path = tmp_path(output_filename)

      _stdout, stderr, status = Open3.capture3(*with_timeout(60,
        "pdftotext", "-layout", input_path, output_path
      ))

      unless status.success?
        raise ExecutionError, "pdftotext extraction failed: #{stderr.strip.presence || 'unknown error'}"
      end

      unless File.exist?(output_path)
        raise ExecutionError, "Failed to generate text output."
      end

      output_path
    end
  end
end
