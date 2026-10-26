require 'pdf-reader'
require 'open3'
require 'grover'
require 'cgi'

module Tools
  class AiTranslatePdf < BaseTool
    CLAUDE_API_URL = AiConfig::CLAUDE[:url]
    CLAUDE_MODEL   = AiConfig::CLAUDE[:model]

    # Right-to-left target languages (only Arabic in the current set).
    RTL_LANGS = %w[ar].freeze

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

      build_output_pdf(translated_text, lang_name, source_name, output_path, rtl: RTL_LANGS.include?(lang_code))
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
      api_key = AiConfig.claude_api_key
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
          'anthropic-version' => AiConfig::CLAUDE[:version]
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

    # Rendered via headless Chromium (Grover), not Prawn: Prawn's built-in fonts
    # are Windows-1252 only and it does no RTL/complex-script shaping, so Arabic,
    # Hindi, CJK, Cyrillic would be broken or blank. Chromium handles every
    # script (shaping, bidi, OS fonts) with no embedded-font assets to ship.
    def build_output_pdf(translated_text, lang_name, source_name, output_path, rtl: false)
      html = translation_html(translated_text, lang_name, source_name, rtl: rtl)

      grover_opts = {
        format:      'A4',
        margin:      { top: '18mm', bottom: '18mm', left: '16mm', right: '16mm' },
        launch_args: ['--no-sandbox', '--disable-setuid-sandbox']
      }
      grover_opts[:executable_path] = ENV['PUPPETEER_EXECUTABLE_PATH'] if ENV['PUPPETEER_EXECUTABLE_PATH'].present?

      File.binwrite(output_path, Grover.new(html, **grover_opts).to_pdf)
      validate_pdf!(output_path)
    rescue ExecutionError
      raise
    rescue => e
      raise ExecutionError, "Failed to generate translated PDF: #{e.message}"
    end

    def translation_html(translated_text, lang_name, source_name, rtl:)
      body = translated_text.to_s.split(/\n{2,}/).filter_map do |para|
        para = para.strip
        next if para.empty?

        if para.length < 80 && para == para.upcase && para.length > 3
          "<h2>#{CGI.escapeHTML(para)}</h2>"
        else
          "<p>#{CGI.escapeHTML(para).gsub("\n", '<br>')}</p>"
        end
      end.join("\n")

      <<~HTML
        <!DOCTYPE html>
        <html dir="#{rtl ? 'rtl' : 'ltr'}">
        <head><meta charset="utf-8"><style>
          body { font-family: -apple-system, "Segoe UI", "Noto Sans", "Noto Sans CJK SC",
                 "Noto Sans Arabic", "Noto Sans Devanagari", sans-serif;
                 font-size: 11pt; color: #1E293B; line-height: 1.55; }
          .brand  { color: #4F46E5; font-size: 9pt;  text-align: center; }
          h1      { color: #1E293B; font-size: 20pt; text-align: center; margin: 4px 0; }
          .src    { color: #64748B; font-size: 9pt;  text-align: center; }
          hr      { border: none; border-top: 1px solid #4F46E5; margin: 14px 0; }
          h2      { font-size: 13pt; margin: 16px 0 4px; }
          p       { margin: 7px 0; }
          .footer { color: #94A3B8; font-size: 8pt; text-align: center;
                    margin-top: 26px; border-top: 1px solid #E2E8F0; padding-top: 6px; }
        </style></head>
        <body>
          <div class="brand">OfficedocTools — AI Translation</div>
          <h1>Translated to #{CGI.escapeHTML(lang_name)}</h1>
          <div class="src">Source: #{CGI.escapeHTML(source_name)}</div>
          <hr>
          #{body}
          <div class="footer">Translated automatically by OfficedocTools AI. Review for accuracy before use.</div>
        </body></html>
      HTML
    end
  end
end
