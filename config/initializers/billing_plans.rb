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
end
