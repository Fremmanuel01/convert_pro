module Tools
  class AiGenerateDocx < BaseTool
    CLAUDE_API_URL = "https://api.anthropic.com/v1/messages"
    CLAUDE_MODEL   = "claude-opus-4-6"

    def self.find_binary
      return "/Applications/LibreOffice.app/Contents/MacOS/soffice" unless Rails.env.production?
      ['libreoffice', 'soffice'].find { |bin| system("which #{bin} > /dev/null 2>&1") } || "soffice"
    end

    SOFFICE_BIN = ENV.fetch("SOFFICE_BIN", find_binary)

    protected

    def process(input_paths)
      prompt = @conversion.options&.dig('prompt')
      raise ExecutionError, "Please describe the document you'd like to create." if prompt.blank?

      html_content = call_claude_api(prompt)

      # Write HTML to temp file
      html_path = tmp_path("document.html")
      File.write(html_path, html_content)

      # LibreOffice converts HTML → DOCX
      profile_dir = tmp_path("lo_profile_#{Time.now.to_f}")
      command = [
        SOFFICE_BIN,
        "-env:UserInstallation=file://#{profile_dir}",
        "-env:JFW_PLUGIN_DO_NOT_CHECK_ACCESSIBILITY=1",
        "--nofirststartwizard",
        "--headless",
        "--convert-to", "docx:MS Word 2007 XML",
        "--outdir", @tmp_dir,
        html_path
      ]

      require 'open3'
      stdout, stderr, status = Open3.capture3(*command)

      unless status.success?
        raise ExecutionError, "Failed to generate DOCX: #{stderr.strip.presence || stdout.strip}"
      end

      output_path = tmp_path("document.docx")
      raise ExecutionError, "DOCX file was not created." unless File.exist?(output_path)

      output_path
    end

    private

    def call_claude_api(topic)
      api_key = ENV['ANTHROPIC_API_KEY']
      raise ExecutionError, "Anthropic API key not configured (ANTHROPIC_API_KEY)." if api_key.blank?

      user_prompt = <<~PROMPT
        Write a professional Word document about: #{topic}

        Return ONLY valid HTML (no markdown, no code fences). The HTML should:
        - Have a proper <html><head><body> structure
        - Include a <style> block with clean typography (font-family: Calibri, Arial; line-height: 1.6; max-width: 800px; margin: 40px auto; color: #1e293b)
        - Use semantic tags: <h1> for the document title, <h2> for section headers, <h3> for sub-sections, <p> for paragraphs, <ul>/<li> for lists
        - Style h1 with color #4F46E5 (indigo), h2 with color #1E293B (dark), horizontal rules between major sections
        - Be comprehensive, professional, and well-structured
        - Include an executive summary, multiple detailed sections, and a conclusion
        - Minimum 600 words of actual content
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
        timeout: 90
      )

      unless response.success?
        msg = response.dig('error', 'message') || "HTTP #{response.code}"
        raise ExecutionError, "Claude API error: #{msg}"
      end

      raw = response.dig('content', 0, 'text').to_s.strip
      # Strip accidental markdown code fences
      raw.gsub(/\A```(?:html)?\n?/, '').gsub(/\n?```\z/, '').strip
    rescue HTTParty::Error, Net::ReadTimeout, SocketError => e
      raise ExecutionError, "Network error connecting to Claude API: #{e.message}"
    end
  end
end
