class BillingController < ApplicationController
  before_action :authenticate_user!

  def show
  end

  def upgrade
  end

  def create_subscription
    plan_type = params[:plan] == 'yearly' ? 'yearly' : 'monthly'
    paystack = PaystackService.new
    url = paystack.initialize_subscription(current_user, callback_url: callback_billing_url, plan: plan_type)

    if url
      redirect_to url, allow_other_host: true
    else
      redirect_to upgrade_billing_path, alert: "Unable to start checkout. Please try again."
    end
  rescue PaystackService::ConfigurationError
    redirect_to upgrade_billing_path, alert: "Payment system not configured yet."
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
        
        current_user.update!(
          plan: :pro,
          subscription_status: :active,
          paystack_customer_code: customer_code,
          paystack_subscription_code: sub_code
        )
      end
    end
    
    # We render the success UI page (the template handles showing success based on user plan)
  end
end
