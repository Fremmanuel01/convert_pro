require 'open3'

module Tools
  class JpgToPng < BaseTool
    protected

    def process(input_paths)
      if input_paths.size > 1
        raise ExecutionError, "JPG to PNG only accepts a single file."
      end

      input_path = input_paths.first
      output_filename = File.basename(input_path, ".*") + ".png"
      output_path = tmp_path(output_filename)

      opts    = @conversion.try(:options) || {}
      quality = opts['quality'].to_i
      quality = 90 if quality < 1 || quality > 100

      _stdout, stderr, status = Open3.capture3(*with_timeout(60,
        "magick", input_path, "-quality", quality.to_s, output_path
      ))

      unless status.success?
        raise ExecutionError, "ImageMagick conversion failed: #{stderr.strip.presence || 'unknown error'}"
      end

      unless File.exist?(output_path)
        raise ExecutionError, "Failed to generate PNG output."
      end

      output_path
    end
  end
end
