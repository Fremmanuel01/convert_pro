require 'pdf-reader'
require 'open3'
require 'prawn'

module Tools
  class SummarizePdf < BaseTool
    protected

    def process(input_paths)
      if input_paths.size > 1
        raise ExecutionError, "The AI Summarizer only accepts a single PDF document at a time."
      end

      input_path = input_paths.first
      output_filename = File.basename(input_path, ".*") + "_AI_Summary.pdf"
      expected_output_path = tmp_path(output_filename)

      # 1. Extract Text from PDF
      extracted_text = extract_text_from_pdf(input_path)

      # If no text found, try OCR as fallback for image-based PDFs
      if extracted_text.strip.empty?
        ocr_path = tmp_path("ocr_output.pdf")
        ocr_bin = `which ocrmypdf 2>/dev/null`.strip
        if ocr_bin.present?
          Rails.logger.info("SummarizePdf: No text found, attempting OCR...")
          stdout, stderr, status = Open3.capture3(ocr_bin, "--force-ocr", input_path, ocr_path)
          if status.success? && File.exist?(ocr_path)
            extracted_text = extract_text_from_pdf(ocr_path)
          end
        end
      end

      if extracted_text.strip.empty?
        raise ExecutionError, "Could not extract any readable text from this PDF, even after OCR. The file may be corrupted or contain only blank pages."
      end

      # Truncate text if it's absurdly long to avoid blowing up the API token limits
      # ~100k characters is a safe limit for GPT-4o-mini
      extracted_text = extracted_text[0..100000]

      # 2. Call AI API for Summarization
      opts       = @conversion.try(:options) || {}
      tone       = opts['tone'].presence || 'professional'
      page_count = opts['page_count'].to_i
      page_count = 3 if page_count < 1
      summary_markdown = generate_ai_summary(extracted_text, tone: tone, page_count: page_count)

      # 3. Generate PDF using Prawn
      create_summary_pdf(summary_markdown, File.basename(input_path), expected_output_path)

      expected_output_path
    end

    private

    def extract_text_from_pdf(path)
      # Try pdftotext first (more robust), fall back to pdf-reader gem
      pdftotext_bin = `which pdftotext 2>/dev/null`.strip
      
      if pdftotext_bin.present?
        stdout, stderr, status = Open3.capture3(pdftotext_bin, path, "-")
        if status.success? && stdout.strip.present?
          return stdout
        end
        Rails.logger.warn "pdftotext returned empty or failed (#{stderr}), falling back to pdf-reader"
      end

      # Fallback: pdf-reader gem
      text = ""
      PDF::Reader.new(path).pages.each do |page|
        text << page.text.to_s << "\n\n"
      end
      text
    rescue => e
      Rails.logger.error "Text extraction error: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
      raise ExecutionError, "Failed to extract text from PDF: #{e.message}"
    end

    def generate_ai_summary(text, tone: 'professional', page_count: 3)
      api_key = ENV['GROQ_API_KEY']

      if api_key.blank?
        raise ExecutionError, "Groq API Key is missing! Please configure GROQ_API_KEY."
      end

      length_guide = case page_count
                     when 1 then "Write a concise summary (approximately 300 words)."
                     when 5 then "Write a detailed summary (approximately 1200 words)."
                     else        "Write a standard summary (approximately 600–800 words)."
                     end

      tone_guide = case tone
                   when 'academic'   then "Use formal academic language with precise terminology."
                   when 'simple'     then "Use plain, simple language that anyone can understand."
                   when 'executive'  then "Write in a sharp executive briefing style — key decisions and bottom-line impact first."
                   else                   "Use professional, clear business language."
                   end

      begin
        prompt = <<~PROMPT
          You are an expert document analyst. Summarize the following document accurately.
          #{tone_guide}
          #{length_guide}
          Format your output strictly in Markdown. Use headers (##), bullet points for key takeaways, and **bold** for important terms.

          --- DOCUMENT TEXT ---
          #{text}
        PROMPT

        url = "https://api.groq.com/openai/v1/chat/completions"

        headers = {
          'Content-Type' => 'application/json',
          'Authorization' => "Bearer #{api_key}"
        }

        body = {
          model: "llama-3.3-70b-versatile",
          messages: [{ role: "user", content: prompt }],
          temperature: 0.3
        }

        response = HTTParty.post(url, headers: headers, body: body.to_json, timeout: 60)

        if response.success?
          response.dig("choices", 0, "message", "content")
        else
          error_msg = response.dig("error", "message") || "Unknown AI Error (Status: #{response.code})"
          raise ExecutionError, "AI Summary Generation Failed: #{error_msg}"
        end

      rescue HTTParty::Error, Net::ReadTimeout, SocketError => e
        Rails.logger.error "Groq Connection Error: #{e.message}"
        raise ExecutionError, "Network error connecting to AI Service: #{e.message}"
      rescue ExecutionError => e
        raise e
      rescue => e
        Rails.logger.error "Groq Backend Error: #{e.message}"
        raise ExecutionError, "The AI summary engine failed: #{e.message}"
      end
    end

    def create_summary_pdf(markdown, source_filename, output_path)
      Prawn::Document.generate(output_path, page_size: 'A4', margin: 40) do |pdf|
        # Header
        pdf.fill_color "4338ca"
        pdf.text "OfficedocTools AI Analysis", size: 10, align: :center
        pdf.move_down 8
        pdf.text "Executive Summary", size: 22, style: :bold, align: :center
        pdf.fill_color "64748b"
        pdf.text "Source: #{source_filename}", size: 10, align: :center
        pdf.move_down 5
        pdf.fill_color "6366f1"
        pdf.stroke_horizontal_rule
        pdf.move_down 20

        # Body - render markdown lines
        pdf.fill_color "1e293b"
        markdown.each_line do |line|
          line = line.strip
          next if line.empty?

          # Strip bold markers for Prawn (no inline styling support)
          clean = line.gsub(/\*\*(.*?)\*\*/, '\1')

          if line.start_with?('# ')
            pdf.move_down 12
            pdf.text clean.sub(/^#+ /, ''), size: 18, style: :bold
            pdf.move_down 4
          elsif line.start_with?('## ')
            pdf.move_down 10
            pdf.text clean.sub(/^#+ /, ''), size: 15, style: :bold
            pdf.move_down 3
          elsif line.start_with?('### ')
            pdf.move_down 8
            pdf.text clean.sub(/^#+ /, ''), size: 13, style: :bold
            pdf.move_down 2
          elsif line.start_with?('- ') || line.start_with?('* ')
            pdf.indent(15) do
              pdf.text "\u2022 #{clean.sub(/^[-*] /, '')}", size: 10, leading: 4
            end
          else
            pdf.text clean, size: 10, leading: 4
          end
        end

        # Footer
        pdf.move_down 30
        pdf.fill_color "94a3b8"
        pdf.stroke_horizontal_rule
        pdf.move_down 8
        pdf.text "Generated automatically by OfficedocTools AI Engine.", size: 8, align: :center
        pdf.text "AI-generated content should be reviewed for accuracy.", size: 8, align: :center
      end
    rescue => e
      Rails.logger.error "Prawn PDF Error: #{e.message}\n#{e.backtrace.first(3).join("\n")}"
      raise ExecutionError, "Failed to generate summary PDF: #{e.message}"
    end

  end
end
