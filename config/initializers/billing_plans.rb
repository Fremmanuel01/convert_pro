# Single source of truth for subscription pricing.
#
# Previously the UI advertised USD ($5 / $50) while PaystackService charged
# NGN (₦5,000 / ₦50,000). These MUST agree. This config is authoritative: both
# the checkout amount sent to Paystack AND the price shown in the UI read from
# here, so they can never drift again.
#
# Authoritative pricing: USD (product decision, Sprint 1). amount_minor is in the
# currency's minor unit (cents). PaystackService charges these exact amounts and
# passes CURRENCY, and the UI renders display_price — so charge and display can
# never disagree.
#
# PRODUCTION REQUIREMENT: the Paystack account must have USD-denominated plans and
# PAYSTACK_MONTHLY_PLAN_CODE / PAYSTACK_YEARLY_PLAN_CODE must point at them.
module BillingPlans
  CURRENCY        = ENV.fetch("BILLING_CURRENCY", "USD")        # ISO 4217
  CURRENCY_SYMBOL = ENV.fetch("BILLING_CURRENCY_SYMBOL", "$")

  PLANS = {
    "monthly" => {
      amount_minor: Integer(ENV.fetch("PRICE_MONTHLY_MINOR", 500)),    # $5.00
      plan_code_env: "PAYSTACK_MONTHLY_PLAN_CODE",
      cycle: "month"
    },
    "yearly" => {
      amount_minor: Integer(ENV.fetch("PRICE_YEARLY_MINOR", 5_000)),   # $50.00
      plan_code_env: "PAYSTACK_YEARLY_PLAN_CODE",
      cycle: "year"
    }
  }.freeze

  def self.fetch(cycle)
    PLANS[cycle.to_s] || PLANS["monthly"]
  end

  def self.amount_minor(cycle)
    fetch(cycle)[:amount_minor]
  end

  def self.plan_code(cycle)
    ENV[fetch(cycle)[:plan_code_env]] || ENV["PAYSTACK_PLAN_CODE"]
  end

  # e.g. "₦5,000" — major units with thousands separators.
  def self.display_price(cycle)
    major = amount_minor(cycle) / 100
    "#{CURRENCY_SYMBOL}#{major.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
  end

  # ── Plan value, described by OUTCOME (not a feature matrix) ────────────────
  # Single source for pricing, dashboard and contextual upsell copy. Limits read
  # from AppLimits so nothing is hardcoded twice. No dark patterns: no fake
  # "most popular", no invented scarcity.
  def self.free_features
    [
      { icon: "all_inclusive", text: "Unlimited conversions on all basic tools" },
      { icon: "auto_awesome",  text: "#{ConversionLimiter::FREE_PREMIUM_CREDITS} free AI or OCR conversion to try" },
      { icon: "check_circle", text: "All #{ToolRegistry.tools.size} document & image tools" },
      { icon: "check_circle", text: "Files up to #{AppLimits::FREE_MAX_UPLOAD_MB} MB" },
      { icon: "check_circle", text: "Secure processing, auto-deleted after" }
    ]
  end

  def self.pro_features
    [
      { icon: "auto_awesome",  text: "Unlimited AI & OCR tools" },
      { icon: "cloud_upload",  text: "Large files up to #{AppLimits::PRO_MAX_UPLOAD_MB} MB" },
      { icon: "bolt",          text: "Priority processing queue" },
      { icon: "history",       text: "30-day conversion history" },
      { icon: "all_inclusive", text: "Unlimited conversions, no limits" }
    ]
  end

  # Short "why upgrade" lines keyed by the friction the user just hit.
  def self.upgrade_reason(key)
    {
      "quota"  => { title: "Do more with Pro",
                    body:  "Pro adds unlimited AI & OCR, larger files and a priority queue." },
      "size"   => { title: "This file is over the #{AppLimits::FREE_MAX_UPLOAD_MB} MB free limit",
                    body:  "Pro handles files up to #{AppLimits::PRO_MAX_UPLOAD_MB} MB." },
      "batch"  => { title: "Converting a lot of files?",
                    body:  "Pro gives you a priority queue and larger uploads." },
      "ai"     => { title: "You've used your free AI & OCR try",
                    body:  "Upgrade to Pro for unlimited AI summaries, translation, document generation and OCR." }
    }.fetch(key.to_s, {
      title: "Do more with Pro",
      body:  "Unlimited AI & OCR, larger files and priority processing." })
  end
end
