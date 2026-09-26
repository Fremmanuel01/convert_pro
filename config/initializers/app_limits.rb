# Central, product-tunable limits. Keep every quota / size / abuse threshold
# here (or referenced from here) so they can later be driven from configuration
# without hunting through the codebase.
module AppLimits
  # Per-upload size ceilings by plan (enforced server-side in ToolRunner).
  FREE_MAX_UPLOAD_MB = Integer(ENV.fetch("FREE_MAX_UPLOAD_MB", 10))
  PRO_MAX_UPLOAD_MB  = Integer(ENV.fetch("PRO_MAX_UPLOAD_MB", 100))

  # A single user may only have this many conversions in flight (pending or
  # processing) at once, so expensive native jobs can't be spawned indefinitely.
  MAX_CONCURRENT_JOBS_PER_USER = Integer(ENV.fetch("MAX_CONCURRENT_JOBS_PER_USER", 5))

  # Rack::Attack throttles (period is in seconds). "expensive" covers AI /
  # LibreOffice / OCR / headless-Chrome tools which cost far more per run.
  RATE_LIMITS = {
    conversions_per_ip:        { limit: Integer(ENV.fetch("RL_CONV_IP", 30)),        period: 60 },
    expensive_per_ip:          { limit: Integer(ENV.fetch("RL_EXPENSIVE_IP", 8)),    period: 60 },
    conversions_per_user:      { limit: Integer(ENV.fetch("RL_CONV_USER", 60)),      period: 60 },
    accounting_per_ip:         { limit: Integer(ENV.fetch("RL_ACCT_IP", 60)),        period: 60 },
    logins_per_ip:             { limit: Integer(ENV.fetch("RL_LOGIN_IP", 20)),       period: 60 },
    signups_per_ip:            { limit: Integer(ENV.fetch("RL_SIGNUP_IP", 10)),      period: 3600 }
  }.freeze

  # Tool ids whose processing is materially more expensive than the rest.
  EXPENSIVE_TOOL_IDS = %w[
    ai_generate_pptx ai_generate_docx ai_translate_pdf summarize_pdf
    ocr_pdf pdf_to_docx docx_to_pdf xlsx_to_pdf pptx_to_pdf webpage_to_pdf
  ].freeze

  def self.max_upload_mb(user)
    user&.pro? && user&.active? ? PRO_MAX_UPLOAD_MB : FREE_MAX_UPLOAD_MB
  end

  # Document retention windows (CleanupConversionsJob). Uploads and outputs for a
  # conversion are purged together with the record once it exceeds its window.
  # NOTE: not surfaced in the UI yet — the commercial privacy promise is TBD.
  module Retention
    FREE_HOURS      = Integer(ENV.fetch("RETENTION_FREE_HOURS", 24))
    GUEST_HOURS     = Integer(ENV.fetch("RETENTION_GUEST_HOURS", 24))
    PRO_DAYS        = Integer(ENV.fetch("RETENTION_PRO_DAYS", 30))
    FAILED_HOURS    = Integer(ENV.fetch("RETENTION_FAILED_HOURS", 6))
    # A pending/processing conversion untouched this long is considered abandoned
    # (worker crashed / lost) and is reclaimed: marked failed and quota refunded.
    ABANDONED_HOURS = Integer(ENV.fetch("RETENTION_ABANDONED_HOURS", 1))
  end
end
