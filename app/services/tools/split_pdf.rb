require 'combine_pdf'
require 'zip'

module Tools
  class SplitPdf < BaseTool
    protected

    def process(input_paths)
      if input_paths.size > 1
        raise ExecutionError, "Split PDF only accepts a single file."
      end

      input_path = input_paths.first
      
      begin
        pdf = CombinePDF.load(input_path)
      rescue => e
        raise ExecutionError, "Failed to read PDF: #{e.message}"
      end

      if pdf.pages.size < 2
        raise ExecutionError, "PDF must have at least 2 pages to split."
      end

      # 1. Write individual pages to tmp dir
      page_paths = []
      pdf.pages.each_with_index do |page, index|
        single_page_pdf = CombinePDF.new
        single_page_pdf << page
        
        page_path = tmp_path("page_#{index + 1}.pdf")
        single_page_pdf.save(page_path)
        page_paths << page_path
      end

      # 2. Add them to a zip archive
      zip_path = tmp_path("split_documents.zip")
      
      Zip::File.open(zip_path, create: true) do |zipfile|
        page_paths.each do |file_path|
          filename = File.basename(file_path)
          zipfile.add(filename, file_path)
        end
      end

      unless File.exist?(zip_path)
        raise ExecutionError, "Failed to generate standard zip output."
      end

      zip_path
    end
  end
end
