

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
        grover_opts = {
          format: 'A4',
          launch_args: ['--no-sandbox', '--disable-setuid-sandbox']
        }
        if ENV['PUPPETEER_EXECUTABLE_PATH'].present?
          grover_opts[:executable_path] = ENV['PUPPETEER_EXECUTABLE_PATH']
        end
        grover = Grover.new(url, grover_opts)
        pdf_content = grover.to_pdf
        
        File.binwrite(output_path, pdf_content)
      rescue => e
        Rails.logger.error "WebpageToPdf Error: #{e.message}\n#{e.backtrace.first(3).join("\n")}"
        raise ExecutionError, "Webpage conversion failed: #{e.message}"
      end

      unless File.exist?(output_path)
        raise ExecutionError, "Failed to extract Webpage layout onto PDF buffer."
      end

      validate_pdf!(output_path)
      output_path
    end
  end
end
