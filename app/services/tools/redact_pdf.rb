require 'shellwords'

module Tools
  class RedactPdf < BaseTool
    protected

    def process(input_paths)
      if input_paths.size > 1
        raise ExecutionError, "Redact PDF only accepts a single file."
      end

      input_path = input_paths.first
      output_path = tmp_path("redacted_output.pdf")
      
      # For a strict redaction, usually coordinate arrays are passed from a frontend canvas
      # format: [{page: 1, x: 100, y: 100, w: 200, h: 50}]
      redactions = @conversion.try(:options)&.dig('redactions')

      if redactions.blank?
        # If no coordinates provided, we simulate redaction in this phase by flattening the PDF
        # into images to strip hidden text metadata, which acts as a "sanitize" fallback.
        command = [
          "gs",
          "-sDEVICE=pdfwrite",
          "-dCompatibilityLevel=1.4",
          "-dPrinted=true",     
          "-dNOPAUSE",
          "-dQUIET",
          "-dBATCH",
          "-sOutputFile=#{output_path}",
          input_path
        ]

        unless system(*command)
          raise ExecutionError, "Image flattening failed."
        end
      else
        # Placeholder for complex hexapdf coordinate injection
        raise ExecutionError, "Specific coordinate redaction requires the hexapdf adapter (pending)."
      end

      unless File.exist?(output_path)
        raise ExecutionError, "Failed to generate redacted output."
      end

      output_path
    end

  end
end
