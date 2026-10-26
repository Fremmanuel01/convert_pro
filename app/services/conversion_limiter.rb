class ConversionLimiter
  # ── Capability-gated free tier ─────────────────────────────────────────────
  # Basic tools (convert / compress / merge / images / etc.) are free and
  # UNLIMITED — they build the habit and keep users (and repeat SEO traffic)
  # coming back. The premium capabilities below are Pro, with the FIRST one free
  # as a taste so users feel the value before the paywall.
  PREMIUM_TOOL_IDS = %w[
    ocr_pdf summarize_pdf ai_translate_pdf ai_generate_docx ai_generate_pptx
  ].freeze

  FREE_PREMIUM_CREDITS = Integer(ENV.fetch("FREE_PREMIUM_CREDITS", 1))

  def self.premium?(tool_id)
    PREMIUM_TOOL_IDS.include?(tool_id.to_s)
  end

  # Map a stored Conversion#tool_name (class name) back to its tool_id.
  def self.tool_id_for(tool_name)
    ToolRegistry.tools.find { |t| t[:class_name] == tool_name }&.dig(:id)
  end

  def initialize(user)
    @user = user
  end

  def unlimited?
    !!(@user&.pro? && @user&.active?)
  end

  # Can this user run `tool_id`? Basic tools: always. Premium: Pro, or a free
  # user who still has a premium credit left.
  def can_convert?(tool_id = nil)
    return true if @user.nil? || unlimited?
    return false unless @user.free? # lapsed Pro must renew
    return true unless self.class.premium?(tool_id)
    premium_credits_remaining?
  end

  def premium_credits_remaining?
    return false if @user.nil?
    @user.premium_credits_used.to_i < FREE_PREMIUM_CREDITS
  end

  # Atomically consume quota for `tool_id`. Basic tools never block (they only
  # bump the lifetime stat counter). Premium tools consume a free credit; once
  # spent, a free user is blocked. Race-safe via the conditional UPDATE.
  def claim!(tool_id = nil)
    return true if @user.nil? || unlimited?
    return false unless @user.free? # lapsed Pro blocked until renewal

    if self.class.premium?(tool_id)
      rows = User.where(id: @user.id)
                 .where("premium_credits_used < ?", FREE_PREMIUM_CREDITS)
                 .update_all("premium_credits_used = premium_credits_used + 1, conversions_count = conversions_count + 1")
      claimed = rows == 1
    else
      User.where(id: @user.id).update_all("conversions_count = conversions_count + 1")
      claimed = true
    end

    @user.reload if claimed
    claimed
  end

  # Give back a claimed unit when a conversion ultimately fails. Tool-aware so a
  # premium credit is restored for premium tools, never below zero.
  def refund!(tool_id = nil)
    return false if @user.nil? || unlimited?

    rows =
      if self.class.premium?(tool_id)
        User.where(id: @user.id).where("premium_credits_used > 0")
            .update_all("premium_credits_used = premium_credits_used - 1, conversions_count = GREATEST(conversions_count - 1, 0)")
      else
        User.where(id: @user.id).where("conversions_count > 0")
            .update_all("conversions_count = conversions_count - 1")
      end

    refunded = rows == 1
    @user.reload if refunded
    refunded
  end

  alias_method :increment!, :claim!

  # Message for the upgrade prompt when a conversion is blocked.
  def status_message(tool_id = nil)
    if @user.nil?
      "Please sign up to download your files."
    elsif unlimited?
      "Unlimited on Pro."
    elsif @user.pro? && !@user.active?
      "Your Pro subscription is inactive. Please update your billing."
    elsif self.class.premium?(tool_id)
      "You've used your free AI & OCR try. Upgrade to Pro for unlimited AI and OCR."
    else
      "Unlimited free conversions on basic tools."
    end
  end

  # Reason key for BillingPlans.upgrade_reason, used by the contextual prompt.
  def block_reason(tool_id = nil)
    self.class.premium?(tool_id) ? "ai" : "quota"
  end
end
