require 'combine_pdf'

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
      
      # Confirm output generated
      unless File.exist?(output_path)
        raise ExecutionError, "Merge failed to produce an output file."
      end

      output_path
    end
  end
end
