require 'rails_helper'

RSpec.describe "Pages", type: :request do
  let(:user) { create(:user) } # Needs FactoryBot

  describe "GET /pricing" do
    it "returns success for unauthenticated users" do
      get pricing_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /dashboard" do
    it "redirects unauthenticated users" do
      get dashboard_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "allows authenticated users" do
      sign_in user
      get dashboard_path
      expect(response).to have_http_status(:success)
    end
  end
end
