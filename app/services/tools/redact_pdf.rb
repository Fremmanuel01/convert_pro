require 'open3'

module Tools
  class RedactPdf < BaseTool
    protected

    def process(input_paths)
      if input_paths.size > 1
        raise ExecutionError, "Redact PDF only accepts a single file."
      end

      input_path = input_paths.first
      output_path = tmp_path("redacted_output.pdf")

      redactions = @conversion.try(:options)&.dig('redactions')

      if redactions.present?
        raise ExecutionError, "Specific coordinate redaction requires the hexapdf adapter (pending)."
      end

      # Sanitise: re-render through Ghostscript to strip hidden text/metadata layers
      command = with_timeout(120,
        "gs",
        "-sDEVICE=pdfwrite",
        "-dCompatibilityLevel=1.4",
        "-dPrinted=true",
        "-dNOPAUSE",
        "-dQUIET",
        "-dBATCH",
        "-sOutputFile=#{output_path}",
        input_path
      )

      _stdout, stderr, status = Open3.capture3(*command)
      unless status.success?
        raise ExecutionError, "PDF sanitisation failed: #{stderr.strip.presence || 'unknown error'}"
      end

      validate_pdf!(output_path)
      output_path
    end
  end
end
