require 'open3'

module Tools
  class RotatePdf < BaseTool
    protected

    def process(input_paths)
      if input_paths.size > 1
        raise ExecutionError, "Rotate PDF only accepts a single file."
      end

      input_path = input_paths.first
      output_path = tmp_path("rotated_output.pdf")

      degrees = @conversion.try(:options)&.dig('rotation') || '90'
      degrees = degrees.to_s

      unless %w[90 180 270].include?(degrees)
        raise ExecutionError, "Invalid rotation. Must be 90, 180, or 270 degrees."
      end

      _stdout, stderr, status = Open3.capture3(*with_timeout(60,
        "qpdf",
        "--rotate=+#{degrees}",
        input_path,
        output_path
      ))

      unless status.success?
        raise ExecutionError, "PDF rotation failed: #{stderr.strip.presence || 'unknown error'}"
      end

      validate_pdf!(output_path)
      output_path
    end
  end
end
