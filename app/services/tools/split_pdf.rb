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

      opts       = @conversion.try(:options) || {}
      from_page  = opts['from_page'].to_i
      to_page    = opts['to_page'].to_i
      total      = pdf.pages.size

      from_page = 1       if from_page < 1 || from_page > total
      to_page   = total   if to_page   < 1 || to_page   > total
      from_page, to_page  = to_page, from_page if from_page > to_page

      # 1. Write individual pages to tmp dir (within selected range)
      page_paths = []
      pdf.pages[(from_page - 1)..(to_page - 1)].each_with_index do |page, index|
        single_page_pdf = CombinePDF.new
        single_page_pdf << page

        page_path = tmp_path("page_#{from_page + index}.pdf")
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
