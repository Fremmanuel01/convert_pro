require 'rails_helper'

RSpec.describe "Conversion experience surfaces", type: :request do
  describe "GET /pricing (honest, outcome-based)" do
    it "renders Free and Pro without dark patterns" do
      get pricing_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Unlimited conversions")
      expect(response.body).to include("No credit card required")
      expect(response.body).to include("cancel Pro anytime")
      # No fake urgency / deceptive labels
      expect(response.body).not_to match(/Most Popular/i)
      expect(response.body).not_to match(/per day/i)
      expect(response.body).not_to match(/limited time/i)
    end

    it "shows the price from BillingPlans (USD)" do
      get pricing_path
      expect(response.body).to include(BillingPlans.display_price("monthly"))
    end
  end

  describe "GET /billing/upgrade (contextual)" do
    let(:user) { create(:user, confirmed_at: Time.current) }

    it "shows a size-specific reason when redirected from a size limit" do
      sign_in user
      get upgrade_billing_path(reason: "size")
      expect(response.body).to include(BillingPlans.upgrade_reason("size")[:title])
    end

    it "shows a quota-specific reason" do
      sign_in user
      get upgrade_billing_path(reason: "quota")
      expect(response.body).to include("used your free conversions")
    end

    it "renders a plain confirmation with no reason param" do
      sign_in user
      get upgrade_billing_path
      expect(response.body).to include("Continue to secure checkout")
      expect(response.body).to include("Cancel anytime")
    end
  end

  describe "GET /dashboard (returning-user workspace)" do
    let(:user) { create(:user, confirmed_at: Time.current) }

    it "shows quick-access tools, recent activity and honest usage" do
      sign_in user
      get dashboard_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Quick access")
      expect(response.body).to include("Recent conversions")
      expect(response.body).to include("of #{ConversionLimiter::FREE_LIMIT} used")
    end
  end
end

RSpec.describe ToolRunner::LimitExceededError do
  it "carries a reason for contextual upsell" do
    err = ToolRunner::LimitExceededError.new("too big", reason: "size")
    expect(err.reason).to eq("size")
    expect(err.message).to eq("too big")
  end

  it "defaults the reason to quota" do
    expect(ToolRunner::LimitExceededError.new("nope").reason).to eq("quota")
  end
end

RSpec.describe BillingPlans, "plan value config" do
  it "derives free/pro features and price from one source" do
    expect(BillingPlans.free_features.map { |f| f[:text] }.join).to include(ConversionLimiter::FREE_LIMIT.to_s)
    expect(BillingPlans.pro_features.map { |f| f[:text] }.join).to match(/Unlimited/)
    expect(BillingPlans.upgrade_reason("size")[:body]).to include(AppLimits::PRO_MAX_UPLOAD_MB.to_s)
  end
end
