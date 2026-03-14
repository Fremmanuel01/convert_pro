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

      watermark_text = @conversion.try(:options)&.dig('watermark').presence || 'CONFIDENTIAL'

      # Build watermark stamp page with Prawn
      stamp_path = tmp_path("watermark_stamp.pdf")
      build_stamp(stamp_path, watermark_text)

      # Overlay stamp onto every page using CombinePDF
      original = CombinePDF.load(input_path)
      stamp    = CombinePDF.load(stamp_path)

      raise ExecutionError, "Stamp page could not be created." if stamp.pages.empty?

      original.pages.each { |page| page << stamp.pages[0] }
      original.save(output_path)

      unless File.exist?(output_path)
        raise ExecutionError, "Failed to generate watermarked PDF."
      end

      output_path
    end

    private

    def build_stamp(path, text)
      # A4 landscape approximation that CombinePDF can scale to any page
      Prawn::Document.generate(path, page_size: [841.89, 595.28], margin: 0) do |pdf|
        w = pdf.bounds.width
        h = pdf.bounds.height

        pdf.rotate(45, origin: [w / 2.0, h / 2.0]) do
          pdf.fill_color "4F46E5"
          pdf.transparent(0.12) do
            pdf.fill_color "4F46E5"
            pdf.text_box(
              text.upcase,
              at:     [w * 0.05, h * 0.60],
              width:  w * 0.90,
              align:  :center,
              size:   (w / text.length.clamp(3, 20)).clamp(48, 110),
              style:  :bold
            )
          end
        end
      end
    end
  end
end
