require 'mini_magick'

module Tools
  class WebpToPng < BaseTool
    protected

    def process(input_paths)
      if input_paths.size > 1
        raise ExecutionError, "This tool only accepts a single WEBP image at a time."
      end

      input_path = input_paths.first
      output_filename = "cp-#{File.basename(input_path, ".*")}.png"
      expected_output_path = tmp_path(output_filename)

      begin
        opts    = @conversion.try(:options) || {}
        quality = opts['quality'].to_i
        quality = 90 if quality < 1 || quality > 100
        image = MiniMagick::Image.open(input_path)
        image.format "png"
        image.quality quality.to_s
        image.write(expected_output_path)
      rescue => e
        Rails.logger.error "MiniMagick Error: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
        raise ExecutionError, "Failed to convert WEBP to PNG. #{e.message}"
      end

      expected_output_path
    end
  end
end
