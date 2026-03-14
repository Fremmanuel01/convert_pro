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

      # pdftotext is provided by poppler-utils (already in Dockerfile)
      command = ["pdftotext", "-layout", input_path, output_path]

      require 'open3'
      stdout, stderr, status = Open3.capture3(*command)

      unless status.success?
        raise ExecutionError, "pdftotext extraction failed. Error: #{stderr.strip.presence || stdout.strip}"
      end

      unless File.exist?(output_path)
        raise ExecutionError, "Failed to generate text output."
      end

      output_path
    end
  end
end
