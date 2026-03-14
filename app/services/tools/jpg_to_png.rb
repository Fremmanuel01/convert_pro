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
      command = ["magick", input_path, "-quality", quality.to_s, output_path]

      require 'open3'
      stdout, stderr, status = Open3.capture3(*command)

      unless status.success?
        raise ExecutionError, "ImageMagick conversion failed. Error: #{stderr.strip.presence || stdout.strip}"
      end

      unless File.exist?(output_path)
        raise ExecutionError, "Failed to generate PNG output."
      end

      output_path
    end
  end
end
