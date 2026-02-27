require 'rails_helper'

RSpec.describe "Webhooks::Paystacks", type: :request do
  let(:secret_key) { 'sk_test_12345' }
  let(:user) { User.create!(email: "customer@example.com", password: "password", plan: :free) }
  
  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('PAYSTACK_SECRET_KEY').and_return(secret_key)
  end

  def generate_signature(payload)
    OpenSSL::HMAC.hexdigest('SHA512', secret_key, payload.to_json)
  end

  def send_webhook(payload)
    headers = {
      'Content-Type' => 'application/json',
      'x-paystack-signature' => generate_signature(payload)
    }
    post webhooks_paystack_path, params: payload.to_json, headers: headers
  end

  describe "Signature Verification" do
    it "rejects invalid signatures" do
      post webhooks_paystack_path, params: { event: "test" }.to_json, headers: { 'x-paystack-signature' => 'invalid' }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "Idempotency" do
    let(:payload) do
      {
        event: "subscription.create",
        data: {
          id: 12345,
          subscription_code: "SUB_123",
          email_token: "tok_123",
          customer: { email: user.email, customer_code: "CUS_123" }
        }
      }
    end

    it "processes the event the first time and ignores duplicates" do
      expect {
        send_webhook(payload)
      }.to change(WebhookEvent, :count).by(1)
      
      expect(response).to have_http_status(:ok)
      user.reload
      expect(user.plan).to eq("pro")
      expect(user.subscription_status).to eq("active")

      # Send exact same payload again
      expect {
        send_webhook(payload)
      }.not_to change(WebhookEvent, :count)
      
      expect(response).to have_http_status(:ok)
    end
  end

  describe "Event Handling" do
    it "handles subscription.not_renew to set cancelled" do
      user.update!(plan: :pro, subscription_status: :active, paystack_subscription_code: "SUB_ABC")
      
      payload = {
        event: "subscription.not_renew",
        data: {
          id: 999,
          subscription_code: "SUB_ABC"
        }
      }

      send_webhook(payload)
      expect(user.reload.subscription_status).to eq("cancelled")
    end
  end
end
