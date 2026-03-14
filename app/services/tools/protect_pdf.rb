require 'open3'

module Tools
  class ProtectPdf < BaseTool
    protected

    def process(input_paths)
      if input_paths.size > 1
        raise ExecutionError, "Protect PDF only accepts a single file."
      end

      input_path = input_paths.first
      output_filename = File.basename(input_path, ".*") + "_protected.pdf"
      output_path = tmp_path(output_filename)

      password = @conversion.try(:options)&.dig('password').presence
      raise ExecutionError, "A password is required to protect this PDF." if password.blank?

      command = with_timeout(60,
        "qpdf",
        "--encrypt", password, password, "256", "--",
        input_path, output_path
      )

      _stdout, stderr, status = Open3.capture3(*command)
      unless status.success?
        raise ExecutionError, "PDF encryption failed: #{stderr.strip.presence || 'unknown error'}"
      end

      validate_pdf!(output_path)
      output_path
    end
  end
end
