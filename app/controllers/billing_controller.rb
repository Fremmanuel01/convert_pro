class BillingController < ApplicationController
  before_action :authenticate_user!

  def show
  end

  def upgrade
    track_event(:upgrade_viewed, properties: { billing_cycle: params[:plan] == 'yearly' ? 'yearly' : 'monthly' })
  end

  def create_subscription
    plan_type = params[:plan] == 'yearly' ? 'yearly' : 'monthly'
    track_event(:checkout_started, properties: { billing_cycle: plan_type, currency: BillingPlans::CURRENCY })
    paystack = PaystackService.new
    url = paystack.initialize_subscription(current_user, callback_url: callback_billing_url, plan: plan_type)

    redirect_to url, allow_other_host: true
  rescue PaystackService::ConfigurationError
    redirect_to upgrade_billing_path, alert: "Payment system not configured yet."
  rescue StandardError => e
    Rails.logger.error("Billing create_subscription failed for user #{current_user&.id}: #{e.message}")
    redirect_to upgrade_billing_path, alert: "Unable to start checkout right now. Please try again in a moment."
  end

  def callback
    # Paystack redirects back here after checkout (success or failure)
    reference = params[:trxref] || params[:reference]
    
    if reference
      paystack = PaystackService.new
      transaction_data = paystack.verify_transaction(reference)

      if transaction_data && transaction_data['status'] == 'success'
        # Fallback to process subscription locally since webhooks fail to reach localhost
        # The true source of truth is the webhook, but this ensures a seamless dev/prod experience
        customer_code = transaction_data.dig('customer', 'customer_code')
        sub_code = transaction_data.dig('plan_object', 'subscription_code') || transaction_data.dig('authorization', 'subscription_code')
        
        was_active = current_user.active?
        current_user.update!(
          plan: :pro,
          subscription_status: :active,
          paystack_customer_code: customer_code,
          paystack_subscription_code: sub_code
        )
        track_event(:subscription_activated, properties: { source: "callback" }) unless was_active
      end
    end
    
    # We render the success UI page (the template handles showing success based on user plan)
  end
end
