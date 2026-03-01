require 'prawn'

module Tools
  class ImagesToPdf < BaseTool
    protected

    def process(input_paths)
      if input_paths.empty?
        raise ExecutionError, "Images to PDF requires at least one image file."
      end

      output_filename = "images_to_pdf_#{Time.current.to_i}.pdf"
      output_path = tmp_path(output_filename)

      begin
        Prawn::Document.generate(output_path, margin: 0) do |pdf|
          input_paths.each_with_index do |image_path, index|
            # Start a new page for every image except the very first one
            pdf.start_new_page if index > 0
            
            # Fit the image to the standard letter page bounds (612x792 pt in Prawn)
            pdf.image image_path, fit: [pdf.bounds.width, pdf.bounds.height], position: :center, vposition: :center
          end
        end
      rescue => e
        Rails.logger.error "Prawn PDF Generation Failed: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
        raise ExecutionError, "Failed to compile images into PDF format."
      end
      
      unless File.exist?(output_path)
        raise ExecutionError, "Engine failed to output PDF."
      end

      output_path
    end
  end
end
