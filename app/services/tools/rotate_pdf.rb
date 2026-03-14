module Tools
  class RotatePdf < BaseTool
    protected

    def process(input_paths)
      if input_paths.size > 1
        raise ExecutionError, "Rotate PDF only accepts a single file."
      end

      input_path = input_paths.first
      output_path = tmp_path("rotated_output.pdf")

      # Read rotation option: 90, 180, or 270 (default: 90)
      degrees = @conversion.try(:options)&.dig('rotation') || '90'
      degrees = degrees.to_s

      unless %w[90 180 270].include?(degrees)
        raise ExecutionError, "Invalid rotation. Must be 90, 180, or 270 degrees."
      end

      # Ghostscript autorotatepages with explicit page rotation via pdfmark
      # Use qpdf which supports direct rotation
      command = [
        "qpdf",
        "--rotate=+#{degrees}",
        input_path,
        output_path
      ]

      require 'open3'
      stdout, stderr, status = Open3.capture3(*command)

      unless status.success?
        raise ExecutionError, "PDF rotation failed. Error: #{stderr.strip.presence || stdout.strip}"
      end

      unless File.exist?(output_path)
        raise ExecutionError, "Failed to generate rotated PDF."
      end

      output_path
    end
  end
end
