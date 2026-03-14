require 'pdf-reader'
require 'open3'
require 'prawn'

module Tools
  class AiTranslatePdf < BaseTool
    CLAUDE_API_URL = "https://api.anthropic.com/v1/messages"
    CLAUDE_MODEL   = "claude-opus-4-6"

    LANGUAGES = {
      'es' => 'Spanish',    'fr' => 'French',    'de' => 'German',
      'pt' => 'Portuguese', 'it' => 'Italian',   'nl' => 'Dutch',
      'pl' => 'Polish',     'ru' => 'Russian',   'zh' => 'Chinese (Simplified)',
      'ja' => 'Japanese',   'ar' => 'Arabic',    'hi' => 'Hindi',
      'ko' => 'Korean',     'tr' => 'Turkish',   'en' => 'English'
    }.freeze

    protected

    def process(input_paths)
      raise ExecutionError, "AI Translate only accepts a single PDF." if input_paths.size > 1

      input_path   = input_paths.first
      lang_code    = @conversion.try(:options)&.dig('target_language').presence || 'es'
      lang_name    = LANGUAGES[lang_code] || 'Spanish'

      extracted_text = extract_text(input_path)
      raise ExecutionError, "No readable text found in this PDF. Try running OCR first." if extracted_text.strip.empty?

      # Truncate to stay within token limits (~120k chars ≈ 30k tokens)
      extracted_text = extracted_text[0..120_000]

      translated_text = call_claude_api(extracted_text, lang_name)

      source_name  = File.basename(input_path, '.*')
      output_name  = "#{source_name}_#{lang_code}_translated.pdf"
      output_path  = tmp_path(output_name)

      build_output_pdf(translated_text, lang_name, source_name, output_path)
      output_path
    end

    private

    def extract_text(path)
      pdftotext = `which pdftotext 2>/dev/null`.strip
      if pdftotext.present?
        stdout, _, status = Open3.capture3(pdftotext, '-layout', path, '-')
        return stdout if status.success? && stdout.strip.present?
      end

      # Fallback: pdf-reader gem
      text = ''
      PDF::Reader.new(path).pages.each { |page| text << page.text.to_s << "\n\n" }
      text
    rescue => e
      raise ExecutionError, "Text extraction failed: #{e.message}"
    end

    def call_claude_api(text, lang_name)
      api_key = ENV['ANTHROPIC_API_KEY']
      raise ExecutionError, "Anthropic API key not configured (ANTHROPIC_API_KEY)." if api_key.blank?

      user_prompt = <<~PROMPT
        Translate the following document text into #{lang_name}.

        Rules:
        - Translate ALL text faithfully and completely
        - Preserve the original structure: keep paragraphs, headings, and lists intact
        - Do NOT add commentary, explanations, or notes
        - Return ONLY the translated text, nothing else

        --- DOCUMENT TEXT ---
        #{text}
      PROMPT

      response = HTTParty.post(
        CLAUDE_API_URL,
        headers: {
          'Content-Type'      => 'application/json',
          'x-api-key'         => api_key,
          'anthropic-version' => '2023-06-01'
        },
        body: {
          model:      CLAUDE_MODEL,
          max_tokens: 8096,
          messages:   [{ role: 'user', content: user_prompt }]
        }.to_json,
        timeout: 120
      )

      unless response.success?
        msg = response.dig('error', 'message') || "HTTP #{response.code}"
        raise ExecutionError, "Claude API error: #{msg}"
      end

      response.dig('content', 0, 'text').to_s.strip
    rescue HTTParty::Error, Net::ReadTimeout, SocketError => e
      raise ExecutionError, "Network error: #{e.message}"
    end

    def build_output_pdf(translated_text, lang_name, source_name, output_path)
      Prawn::Document.generate(output_path, page_size: 'A4', margin: 50) do |pdf|
        # Header
        pdf.fill_color "4F46E5"
        pdf.text "OfficedocTools — AI Translation", size: 9, align: :center
        pdf.move_down 6
        pdf.fill_color "1E293B"
        pdf.text "Translated to #{lang_name}", size: 20, style: :bold, align: :center
        pdf.fill_color "64748B"
        pdf.text "Source: #{source_name}", size: 9, align: :center
        pdf.move_down 6
        pdf.stroke_color "4F46E5"
        pdf.stroke_horizontal_rule
        pdf.move_down 16

        # Body
        pdf.fill_color "1E293B"
        translated_text.each_line do |line|
          line = line.strip
          next if line.empty?

          if line.length < 80 && line == line.upcase && line.length > 3
            # Likely a heading
            pdf.move_down 10
            pdf.text line, size: 13, style: :bold
            pdf.move_down 4
          else
            pdf.text line, size: 10, leading: 4
          end
        end

        # Footer
        pdf.move_down 20
        pdf.stroke_color "E2E8F0"
        pdf.stroke_horizontal_rule
        pdf.move_down 6
        pdf.fill_color "94A3B8"
        pdf.text "Translated automatically by OfficedocTools AI. Review for accuracy before use.", size: 8, align: :center
      end
    rescue => e
      raise ExecutionError, "Failed to generate translated PDF: #{e.message}"
    end
  end
end
