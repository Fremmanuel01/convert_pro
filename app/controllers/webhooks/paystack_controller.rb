module Webhooks
  class PaystackController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :verify_paystack_signature

    def create
      event_id = params.dig('data', 'id').to_s
      return head :ok if event_id.blank?

      # Idempotency check
      return head :ok if WebhookEvent.exists?(event_id: event_id)

      event_type = params['event']

      begin
        ActiveRecord::Base.transaction do
          process_event(event_type, params['data'])
          WebhookEvent.create!(event_id: event_id, event_type: event_type, processed_at: Time.current)
        end
        head :ok
      rescue StandardError => e
        Rails.logger.error("Paystack Webhook Error [#{event_type}]: #{e.message}")
        head :unprocessable_entity
      end
    end

    private

    def verify_paystack_signature
      secret_key = ENV['PAYSTACK_SECRET_KEY']
      return head :unauthorized unless secret_key

      payload = request.raw_post
      signature = request.headers['x-paystack-signature'].to_s

      expected_signature = OpenSSL::HMAC.hexdigest('SHA512', secret_key, payload)

      unless Rack::Utils.secure_compare(signature, expected_signature)
        head :unauthorized
      end
    end

    def process_event(event_type, data)
      case event_type
      when 'subscription.create'
        handle_subscription_create(data)
      when 'charge.success'
        handle_charge_success(data)
      when 'subscription.not_renew', 'subscription.disable'
        handle_subscription_cancel(data)
      when 'invoice.payment_failed'
        handle_invoice_failed(data)
      end
    end

    def handle_subscription_create(data)
      customer_code = data.dig('customer', 'customer_code')
      sub_code = data['subscription_code']
      email = data.dig('customer', 'email')
      email_token = data['email_token']

      user = User.find_by(email: email)
      return unless user

      user.update!(
        plan: :pro,
        subscription_status: :active,
        paystack_customer_code: customer_code,
        paystack_subscription_code: sub_code,
        paystack_email_token: email_token
      )
    end

    def handle_charge_success(data)
      # Charge success on a subscription ensures it's active
      sub_code = data.dig('plan_object', 'subscription_code') || data.dig('authorization', 'subscription_code')
      return unless sub_code
      
      user = User.find_by(paystack_subscription_code: sub_code)
      return unless user

      user.update!(subscription_status: :active, plan: :pro)
    end

    def handle_subscription_cancel(data)
      sub_code = data['subscription_code']
      user = User.find_by(paystack_subscription_code: sub_code)
      return unless user

      user.update!(subscription_status: :cancelled)
    end

    def handle_invoice_failed(data)
      sub_code = data.dig('subscription', 'subscription_code')
      user = User.find_by(paystack_subscription_code: sub_code)
      return unless user

      user.update!(subscription_status: :incomplete)
    end
  end
end
