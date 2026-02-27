require 'grover'

module Tools
  class WebpageToPdf < BaseTool
    protected

    def process(input_paths)
      url = @conversion.try(:options)&.dig('url')

      if url.blank?
        raise ExecutionError, "Webpage URL is required in options payload."
      end

      output_filename = "webpage_#{Time.current.to_i}.pdf"
      output_path = tmp_path(output_filename)

      begin
        grover = Grover.new(url, format: 'A4', debug_info: true)
        pdf_content = grover.to_pdf
        
        File.binwrite(output_path, pdf_content)
      rescue => e
        raise ExecutionError, "Puppeteer conversion failed: #{e.message}"
      end

      unless File.exist?(output_path)
        raise ExecutionError, "Failed to extract Webpage layout onto PDF buffer."
      end

      output_path
    end
  end
end
