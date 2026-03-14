require 'prawn'

module Tools
  class ImagesToPdf < BaseTool
    PAGE_SIZES = {
      'A4'     => [595.28,  841.89],
      'A3'     => [841.89, 1190.55],
      'Letter' => [612.0,   792.0],
      'Legal'  => [612.0,  1008.0]
    }.freeze

    protected

    def process(input_paths)
      raise ExecutionError, "Images to PDF requires at least one image file." if input_paths.empty?

      opts        = @conversion.try(:options) || {}
      page_size   = opts['page_size'].presence || 'A4'
      orientation = opts['page_orientation'].presence || 'portrait'
      fit_mode    = opts['fit_mode'].presence || 'fit'
      margin_pt   = opts['margin'].present? ? opts['margin'].to_i : 0

      dims = PAGE_SIZES[page_size] || PAGE_SIZES['A4']
      dims = dims.reverse if orientation == 'landscape'

      output_path = tmp_path("images_to_pdf_#{Time.current.to_i}.pdf")

      begin
        Prawn::Document.generate(output_path, page_size: dims, margin: margin_pt) do |pdf|
          input_paths.each_with_index do |image_path, index|
            pdf.start_new_page if index > 0

            w = pdf.bounds.width
            h = pdf.bounds.height

            case fit_mode
            when 'stretch'
              pdf.image image_path, at: [0, h], width: w, height: h
            when 'center'
              pdf.image image_path, position: :center, vposition: :center
            else # 'fit' (default)
              pdf.image image_path, fit: [w, h], position: :center, vposition: :center
            end
          end
        end
      rescue => e
        Rails.logger.error "Prawn PDF Generation Failed: #{e.message}"
        raise ExecutionError, "Failed to compile images into PDF: #{e.message}"
      end

      raise ExecutionError, "Engine failed to output PDF." unless File.exist?(output_path)
      validate_pdf!(output_path)
      output_path
    end
  end
end
