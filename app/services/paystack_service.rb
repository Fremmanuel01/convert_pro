require 'paystack'

class PaystackService
  class ConfigurationError < StandardError; end

  def initialize
    @public_key = ENV['PAYSTACK_PUBLIC_KEY']
    @secret_key = ENV['PAYSTACK_SECRET_KEY']
    @monthly_plan_code = ENV['PAYSTACK_MONTHLY_PLAN_CODE'] || ENV['PAYSTACK_PLAN_CODE']
    @yearly_plan_code  = ENV['PAYSTACK_YEARLY_PLAN_CODE']

    unless @public_key && @secret_key && @monthly_plan_code
      Rails.logger.warn "PaystackService: Missing PAYSTACK environment variables"
    end
    
    # We only initialize the client if we have keys (prevents crashing in test if unstubbed)
    @paystack = Paystack.new(@public_key, @secret_key) if @public_key && @secret_key
  end

  def initialize_subscription(user, callback_url:, plan: 'monthly')
    cycle = (plan.to_s == 'yearly') ? 'yearly' : 'monthly'

    # Amount and plan code both come from the single BillingPlans source of truth,
    # so the charge can never disagree with the price shown in the UI.
    chosen_plan_code = BillingPlans.plan_code(cycle)
    amount_minor     = BillingPlans.amount_minor(cycle)

    raise ConfigurationError, "Paystack credentials missing or Plan Code missing" unless @paystack && chosen_plan_code

    transactions = PaystackTransactions.new(@paystack)

    # Generate a unique reference to track this checkout attempt
    reference = "sub_#{user.id}_#{Time.current.to_i}_#{SecureRandom.hex(4)}"

    payload = {
      email: user.email,
      amount: amount_minor,
      plan: chosen_plan_code,
      reference: reference,
      callback_url: callback_url
    }

    response = transactions.initializeTransaction(payload)
    
    if response['status']
      response['data']['authorization_url']
    else
      err_msg = response['message'] || "Unknown Paystack Error: #{response.inspect}"
      Rails.logger.error("Paystack API Error: #{err_msg}")
      raise StandardError, err_msg
    end
  rescue StandardError => e
    Rails.logger.error("Paystack Initialize Error: #{e.message}")
    raise e
  end

  def verify_transaction(reference)
    return false unless @paystack
    
    transactions = PaystackTransactions.new(@paystack)
    response = transactions.verify(reference)
    
    if response['status'] && response['data']['status'] == 'success'
      return response['data'] # Return the payload for processing
    end
    
    false
  rescue StandardError => e
    Rails.logger.error("Paystack Verify Error: #{e.message}")
    false
  end

  private

  def default_host
    # Tries to get action_mailer host (which we set to localhost:3000 in dev) or default
    Rails.application.config.action_mailer.default_url_options&.fetch(:host, "localhost:3000")
  end
end
