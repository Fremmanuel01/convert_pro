require 'open3'

module Tools
  class CompressPdf < BaseTool
    protected

    def process(input_paths)
      if input_paths.size > 1
        raise ExecutionError, "Compress PDF only accepts a single file."
      end

      input_path = input_paths.first
      output_path = tmp_path("compressed_output.pdf")

      quality_map = {
        'screen'   => '/screen',
        'ebook'    => '/ebook',
        'printer'  => '/printer',
        'prepress' => '/prepress'
      }
      quality = quality_map[@conversion.try(:options)&.dig('quality')] || '/ebook'

      command = with_timeout(120,
        "gs",
        "-sDEVICE=pdfwrite",
        "-dCompatibilityLevel=1.4",
        "-dPDFSETTINGS=#{quality}",
        "-dNOPAUSE",
        "-dQUIET",
        "-dBATCH",
        "-sOutputFile=#{output_path}",
        input_path
      )

      _stdout, stderr, status = Open3.capture3(*command)
      unless status.success?
        raise ExecutionError, "Ghostscript compression failed: #{stderr.strip.presence || 'unknown error'}"
      end

      validate_pdf!(output_path)
      output_path
    end
  end
end
