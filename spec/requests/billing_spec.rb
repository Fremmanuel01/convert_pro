require 'rails_helper'

RSpec.describe "Billing", type: :request do
  let(:user) { create(:user) }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('PAYSTACK_PUBLIC_KEY').and_return('pk_test_123')
    allow(ENV).to receive(:[]).with('PAYSTACK_SECRET_KEY').and_return('sk_test_123')
    allow(ENV).to receive(:[]).with('PAYSTACK_PLAN_CODE').and_return('PLN_123')
  end

  describe "GET /billing" do
    it "redirects unauthenticated users" do
      get billing_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "allows authenticated users" do
      sign_in user
      get billing_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /billing/create_subscription" do
    it "redirects unauthenticated users" do
      post create_subscription_billing_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "initializes paystack and redirects to authorization_url" do
      sign_in user
      
      paystack_response = { 
        'status' => true, 
        'data' => { 'authorization_url' => 'https://checkout.paystack.com/test' } 
      }
      
      # Stub the Paystack API call
      stub_request(:post, "https://api.paystack.co/transaction/initialize").
        to_return(status: 200, body: paystack_response.to_json, headers: {})

      post create_subscription_billing_path
      
      expect(response).to redirect_to('https://checkout.paystack.com/test')
    end

    it "handles paystack API failure gracefully" do
      sign_in user
      
      paystack_response = { 
        'status' => false, 
        'message' => 'Invalid plan' 
      }
      
      stub_request(:post, "https://api.paystack.co/transaction/initialize").
        to_return(status: 400, body: paystack_response.to_json, headers: {})

      post create_subscription_billing_path
      
      expect(response).to redirect_to(upgrade_billing_path)
      expect(flash[:alert]).to include("Unable to start checkout")
    end
  end
end
