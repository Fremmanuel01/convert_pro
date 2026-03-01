require 'shellwords'

module Tools
  class ImagesToPdf < BaseTool
    def self.find_magick_binary
      system("which magick > /dev/null 2>&1") ? "magick" : "convert"
    end

    MAGICK_BIN = ENV.fetch("MAGICK_BIN", find_magick_binary)

    protected

    def process(input_paths)
      if input_paths.empty?
        raise ExecutionError, "Images to PDF requires at least one image file."
      end

      output_filename = "images_to_pdf_#{Time.current.to_i}.pdf"
      output_path = tmp_path(output_filename)

      # Build bash command array to safely utilize ImageMagick with high quality
      command_args = [
        MAGICK_BIN,
        "-density", "300",
        "-quality", "100"
      ]
      command_args += input_paths
      command_args += ["+repage", output_path]
      
      command = command_args.shelljoin

      unless system(command)
        raise ExecutionError, "ImageMagick conversion failed."
      end
      
      unless File.exist?(output_path)
        raise ExecutionError, "Engine failed to output PDF."
      end

      output_path
    end
  end
end
