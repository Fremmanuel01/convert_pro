# Single source of truth for subscription pricing.
#
# Previously the UI advertised USD ($5 / $50) while PaystackService charged
# NGN (₦5,000 / ₦50,000). These MUST agree. This config is authoritative: both
# the checkout amount sent to Paystack AND the price shown in the UI read from
# here, so they can never drift again.
#
# The amounts below are the values Paystack has been charging (kobo, the NGN
# minor unit) — i.e. nothing customers are billed changes. CURRENCY/display are
# provided so the UI shows what is actually charged.
module BillingPlans
  CURRENCY        = ENV.fetch("BILLING_CURRENCY", "NGN")        # ISO 4217
  CURRENCY_SYMBOL = ENV.fetch("BILLING_CURRENCY_SYMBOL", "₦")

  PLANS = {
    "monthly" => {
      amount_minor: Integer(ENV.fetch("PRICE_MONTHLY_MINOR", 500_000)),   # ₦5,000
      plan_code_env: "PAYSTACK_MONTHLY_PLAN_CODE",
      cycle: "month"
    },
    "yearly" => {
      amount_minor: Integer(ENV.fetch("PRICE_YEARLY_MINOR", 5_000_000)),  # ₦50,000
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
end
