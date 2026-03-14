require 'combine_pdf'
require 'prawn'

module Tools
  class WatermarkPdf < BaseTool
    protected

    def process(input_paths)
      if input_paths.size > 1
        raise ExecutionError, "Watermark PDF only accepts a single file."
      end

      input_path  = input_paths.first
      output_path = tmp_path("watermarked_output.pdf")

      opts           = @conversion.try(:options) || {}
      watermark_text = opts['watermark'].presence || 'CONFIDENTIAL'
      opacity        = (opts['opacity'].presence || '15').to_i.clamp(5, 60) / 100.0
      position       = opts['watermark_position'].presence || 'diagonal'

      stamp_path = tmp_path("watermark_stamp.pdf")
      build_stamp(stamp_path, watermark_text, opacity, position)

      # Overlay stamp onto every page using CombinePDF
      original = CombinePDF.load(input_path)
      stamp    = CombinePDF.load(stamp_path)

      raise ExecutionError, "Stamp page could not be created." if stamp.pages.empty?

      original.pages.each { |page| page << stamp.pages[0] }
      original.save(output_path)

      unless File.exist?(output_path)
        raise ExecutionError, "Failed to generate watermarked PDF."
      end

      validate_pdf!(output_path)
      output_path
    end

    private

    def build_stamp(path, text, opacity, position)
      Prawn::Document.generate(path, page_size: [841.89, 595.28], margin: 0) do |pdf|
        w = pdf.bounds.width
        h = pdf.bounds.height
        font_size = (w / text.length.clamp(3, 22)).clamp(36, 120)

        pdf.fill_color "4F46E5"

        case position
        when 'center'
          pdf.transparent(opacity) do
            pdf.text_box(
              text.upcase,
              at:    [0, h / 2.0 + font_size],
              width: w,
              align: :center,
              size:  font_size,
              style: :bold
            )
          end
        when 'header'
          pdf.transparent(opacity) do
            pdf.text_box(text.upcase, at: [40, h - 20], width: w - 80, align: :center, size: 28, style: :bold)
          end
        when 'footer'
          pdf.transparent(opacity) do
            pdf.text_box(text.upcase, at: [40, 50], width: w - 80, align: :center, size: 28, style: :bold)
          end
        else # 'diagonal' (default)
          pdf.rotate(45, origin: [w / 2.0, h / 2.0]) do
            pdf.transparent(opacity) do
              pdf.text_box(
                text.upcase,
                at:    [w * 0.05, h * 0.62],
                width: w * 0.90,
                align: :center,
                size:  font_size,
                style: :bold
              )
            end
          end
        end
      end
    end
  end
end
