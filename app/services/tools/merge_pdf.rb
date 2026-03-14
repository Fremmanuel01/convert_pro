require 'combine_pdf'
require 'open3'

module Tools
  class MergePdf < BaseTool
    protected

    def process(input_paths)
      if input_paths.size < 2
        raise ExecutionError, "At least two PDF files are required to merge."
      end

      combined = CombinePDF.new

      input_paths.each do |path|
        begin
          pdf = CombinePDF.load(path)
          combined << pdf
        rescue => e
          raise ExecutionError, "Failed to read PDF #{File.basename(path)}: #{e.message}"
        end
      end

      output_path = tmp_path("merged_output.pdf")
      combined.save(output_path)

      unless File.exist?(output_path)
        raise ExecutionError, "Merge failed to produce an output file."
      end

      # Optional: re-paginate to a standard page size via Ghostscript
      opts      = @conversion.try(:options) || {}
      page_size = opts['page_size'].presence
      if page_size.present?
        gs_size   = { 'A4' => 'a4', 'Letter' => 'letter' }[page_size]
        if gs_size
          resized = tmp_path("merged_resized.pdf")
          cmd = ['gs', '-sDEVICE=pdfwrite', '-dNOPAUSE', '-dBATCH', '-dQUIET',
                 '-dFIXEDMEDIA', '-dPDFFitPage', "-sPAPERSIZE=#{gs_size}",
                 "-sOutputFile=#{resized}", output_path]
          _out, _err, status = Open3.capture3(*with_timeout(120, *cmd))
          output_path = resized if status.success? && File.exist?(resized)
        end
      end

      validate_pdf!(output_path)
      output_path
    end
  end
end
