require 'shellwords'
require 'zip'

module Tools
  class PdfToImages < BaseTool
    protected

    def process(input_paths)
      if input_paths.size > 1
        raise ExecutionError, "PDF to Images only accepts a single file."
      end

      input_path = input_paths.first
      
      # We will extract each page as a JPEG using Ghostscript
      output_pattern = tmp_path("page_%03d.jpg")

      command = [
        "gs",
        "-sDEVICE=jpeg",
        "-dJPEGQ=90",      # high quality with reasonable file size
        "-r300",           # 300 DPI for high resolution output
        "-dNOPAUSE",
        "-dQUIET",
        "-dBATCH",
        "-sOutputFile=#{output_pattern}",
        input_path
      ]

      unless system(*command)
        raise ExecutionError, "Ghostscript failed to map PDF arrays."
      end

      # Collect all generated JPEGs
      page_paths = Dir.glob(tmp_path("page_*.jpg"))
      
      if page_paths.empty?
        raise ExecutionError, "Engine failed to extract any image structures."
      end

      # Zip the results via rubyzip natively
      zip_path = tmp_path("extracted_images.zip")
      
      Zip::File.open(zip_path, create: true) do |zipfile|
        page_paths.each do |file_path|
          filename = File.basename(file_path)
          zipfile.add(filename, file_path)
        end
      end

      zip_path
    end
  end
end
