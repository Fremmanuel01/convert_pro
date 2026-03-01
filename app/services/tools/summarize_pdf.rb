require 'pdf-reader'
require 'open3'

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
      
      if extracted_text.strip.empty?
        raise ExecutionError, "Could not extract any readable text from this PDF. It might be an image-based scan without OCR."
      end

      # Truncate text if it's absurdly long to avoid blowing up the API token limits
      # ~100k characters is a safe limit for GPT-4o-mini
      extracted_text = extracted_text[0..100000]

      # 2. Call OpenAI API for Summarization
      summary_markdown = generate_ai_summary(extracted_text)

      # 3. Generate HTML & convert to PDF using Grover
      html_content = build_summary_html(summary_markdown, File.basename(input_path))
      create_pdf_from_html(html_content, expected_output_path)

      expected_output_path
    end

    private

    def extract_text_from_pdf(path)
      # use pdftotext (from poppler-utils) which is much more robust than the ruby gem
      stdout, stderr, status = Open3.capture3("pdftotext", path, "-")
      
      unless status.success?
        Rails.logger.error "pdftotext Error: #{stderr}"
        raise ExecutionError, "Failed to extract text from PDF document. Error: #{stderr.strip}"
      end

      stdout
    rescue => e
      Rails.logger.error "Extraction error: #{e.message}"
      raise ExecutionError, "Failed to parse PDF document for text extraction."
    end

    def generate_ai_summary(text)
      api_key = ENV['GROQ_API_KEY']
      
      if api_key.blank?
        raise ExecutionError, "Groq API Key is missing! The server admin must configure ENV['GROQ_API_KEY']."
      end

      begin
        prompt = <<~PROMPT
          You are an expert executive assistant. Summarize the following document accurately and concisely.
          Format your output strictly in Markdown. Use headers, bullet points for key takeaways, and bold text for important terms.
          Keep the summary comprehensive but readable.

          --- DOCUMENT TEXT ---
          #{text}
        PROMPT
        
        # Use HTTParty to hit the Groq REST API (OpenAI-compatible)
        url = "https://api.groq.com/openai/v1/chat/completions"
        
        headers = { 
          'Content-Type' => 'application/json',
          'Authorization' => "Bearer #{api_key}"
        }
        
        body = {
          model: "llama-3.1-8b-instant", # Fast Llama 3.1 model hosted by Groq
          messages: [{ role: "user", content: prompt }],
          temperature: 0.3
        }

        response = HTTParty.post(url, headers: headers, body: body.to_json, timeout: 30)

        if response.success?
          # Successfully got a completion (matches OpenAI JSON structure)
          response.dig("choices", 0, "message", "content")
        else
          # Capture specific Groq API errors
          error_msg = response.dig("error", "message") || "Unknown Groq API Error (Status: #{response.code})"
          
          if response.code == 429
            raise ExecutionError, "Groq rejected the request (Error 429). Rate limit exceeded."
          elsif response.code == 401
            raise ExecutionError, "The provided Groq API key is invalid or unauthorized."
          else
            raise ExecutionError, "Groq API Error: #{error_msg}"
          end
        end

      rescue HTTParty::Error, Net::ReadTimeout, SocketError => e
        Rails.logger.error "Groq Connection Error: #{e.message}"
        raise ExecutionError, "Network error connecting to Groq AI: #{e.message}"
      rescue ExecutionError => e
        # Re-raise explicit errors
        raise e
      rescue => e
        Rails.logger.error "Groq Backend Error: #{e.message}"
        raise ExecutionError, "The AI engine failed: #{e.message}"
      end
    end

    def build_summary_html(markdown_content, original_filename)
      # Extremely basic markdown to HTML conversion for headers and lists
      # In a full app, you might use 'redcarpet' gem, but we'll do quick regex for MVP
      html = markdown_content
        .gsub(/^### (.*)$/, '<h3>\1</h3>')
        .gsub(/^## (.*)$/, '<h2>\1</h2>')
        .gsub(/^# (.*)$/, '<h1>\1</h1>')
        .gsub(/\*\*(.*?)\*\*/, '<strong>\1</strong>')
        .gsub(/^\* (.*)$/, '<li>\1</li>')
        .gsub(/^- (.*)$/, '<li>\1</li>')
        .gsub(/\n\n/, '</p><p>')
      
      # Wrap bare lists in <ul>
      html.gsub!(/(<li>.*<\/li>)/m, '<ul>\1</ul>')

      <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <style>
          body { font-family: 'Helvetica Neue', Arial, sans-serif; color: #1e293b; margin: 40px; line-height: 1.6; }
          .header { text-align: center; border-bottom: 2px solid #6366f1; padding-bottom: 20px; margin-bottom: 30px; }
          .title { color: #4338ca; font-size: 24px; font-weight: bold; margin-bottom: 5px; }
          .subtitle { color: #64748b; font-size: 14px; }
          .ai-badge { display: inline-block; background-color: #e0e7ff; color: #4f46e5; padding: 4px 12px; border-radius: 20px; font-size: 12px; font-weight: bold; margin-bottom: 15px; }
          h1 { color: #0f172a; font-size: 22px; margin-top: 30px; }
          h2 { color: #1e293b; font-size: 18px; margin-top: 25px; border-bottom: 1px solid #e2e8f0; padding-bottom: 5px;}
          h3 { color: #334155; font-size: 16px; margin-top: 20px; }
          p { margin-bottom: 15px; }
          ul { margin-bottom: 20px; padding-left: 20px; }
          li { margin-bottom: 8px; }
          strong { color: #0f172a; }
          .footer { margin-top: 50px; font-size: 10px; color: #94a3b8; text-align: center; border-top: 1px solid #f1f5f9; padding-top: 10px; }
        </style>
      </head>
      <body>
        <div class="header">
          <div class="ai-badge">ConvertPro AI Analysis</div>
          <div class="title">Executive Summary</div>
          <div class="subtitle">Source Profile: #{original_filename}</div>
        </div>
        
        <p>#{html}</p>

        <div class="footer">
          Generated automatically by ConvertPro Artificial Intelligence Intelligence Engine.<br>
          Responses are machine-generated and should be reviewed for critical accuracy.
        </div>
      </body>
      </html>
      HTML
    end

    def create_pdf_from_html(html, output_path)
      begin
        grover = Grover.new(html, format: 'A4', margin: { top: '20px', bottom: '20px' })
        pdf_data = grover.to_pdf
        File.binwrite(output_path, pdf_data)
      rescue => e
        Rails.logger.error "Grover Render Error: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
        raise ExecutionError, "Failed to render the AI summary into a PDF document. System error: #{e.message}"
      end
    end

  end
end
