# Single source of truth for AI provider/model configuration.
#
# Previously each tool hardcoded its own model id (including the invalid
# "claude-opus-4-6"). Centralizing here means one place to set the model, and
# every model id is overridable via ENV without editing tool code.
#
# NOTE on providers (kept honest, per product decision):
#   - AI Generate PPTX / DOCX / Translate PDF  -> Anthropic Claude
#   - Summarize PDF                            -> Groq (Llama). The UI must not
#                                                 claim Claude for this tool.
module AiConfig
  CLAUDE = {
    url:     "https://api.anthropic.com/v1/messages",
    version: "2023-06-01",
    # Valid, current default; override with ANTHROPIC_MODEL (e.g. claude-opus-4-8).
    model:   ENV.fetch("ANTHROPIC_MODEL", "claude-sonnet-4-6"),
    key_env: "ANTHROPIC_API_KEY"
  }.freeze

  GROQ = {
    url:     "https://api.groq.com/openai/v1/chat/completions",
    model:   ENV.fetch("GROQ_MODEL", "llama-3.3-70b-versatile"),
    key_env: "GROQ_API_KEY"
  }.freeze

  def self.claude_api_key
    ENV[CLAUDE[:key_env]]
  end

  def self.groq_api_key
    ENV[GROQ[:key_env]]
  end
end
