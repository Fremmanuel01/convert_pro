require 'open3'
require 'zip'

module Tools
  class PdfToImages < BaseTool
    protected

    def process(input_paths)
      if input_paths.size > 1
        raise ExecutionError, "PDF to Images only accepts a single file."
      end

      input_path = input_paths.first

      opts   = @conversion.try(:options) || {}
      dpi    = [72, 150, 300].include?(opts['dpi'].to_i) ? opts['dpi'].to_i : 150
      fmt    = opts['image_format'] == 'png' ? 'png16m' : 'jpeg'
      ext    = opts['image_format'] == 'png' ? 'png'   : 'jpg'
      output_pattern = tmp_path("page_%03d.#{ext}")

      gs_args = [
        "gs",
        "-sDEVICE=#{fmt}",
        ("-dJPEGQ=92" if ext == 'jpg'),
        "-r#{dpi}",
        "-dNOPAUSE",
        "-dQUIET",
        "-dBATCH",
        "-sOutputFile=#{output_pattern}",
        input_path
      ].compact

      _stdout, stderr, status = Open3.capture3(*with_timeout(120, *gs_args))
      raise ExecutionError, "Image extraction failed: #{stderr.strip}" unless status.success?

      page_paths = Dir.glob(tmp_path("page_*.#{ext}")).sort

      if page_paths.empty?
        raise ExecutionError, "Engine failed to extract any image structures."
      end

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
