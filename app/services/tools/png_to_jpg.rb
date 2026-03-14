module Tools
  class PngToJpg < BaseTool
    protected

    def process(input_paths)
      if input_paths.size > 1
        raise ExecutionError, "PNG to JPG only accepts a single file."
      end

      input_path = input_paths.first
      output_filename = File.basename(input_path, ".*") + ".jpg"
      output_path = tmp_path(output_filename)

      # Flatten to white background to handle transparency before converting to JPG
      command = ["magick", input_path, "-background", "white", "-flatten", output_path]

      require 'open3'
      stdout, stderr, status = Open3.capture3(*command)

      unless status.success?
        raise ExecutionError, "ImageMagick conversion failed. Error: #{stderr.strip.presence || stdout.strip}"
      end

      unless File.exist?(output_path)
        raise ExecutionError, "Failed to generate JPG output."
      end

      output_path
    end
  end
end
