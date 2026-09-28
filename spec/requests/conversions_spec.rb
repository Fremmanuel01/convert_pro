require 'rails_helper'

RSpec.describe "Conversions", type: :request do
  let(:owner)     { create(:user, confirmed_at: Time.current) }
  let(:other)     { create(:user, confirmed_at: Time.current) }
  let(:owned)     { Conversion.create!(user: owner, tool_name: "Tools::CompressPdf", status: :completed) }

  describe "GET /conversions/:id (ownership / IDOR)" do
    it "lets the owner view their conversion" do
      sign_in owner
      get conversion_path(owned)
      expect(response).to have_http_status(:success)
    end

    it "does NOT let another signed-in user view someone else's conversion" do
      sign_in other
      get conversion_path(owned)
      expect(response).to redirect_to(root_path)
    end

    it "does not let a signed-in user view an unclaimed guest conversion they don't own" do
      guest = Conversion.create!(user: nil, tool_name: "Tools::MergePdf", status: :completed)
      sign_in other
      get conversion_path(guest)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /conversions/:id/download (ownership / IDOR)" do
    it "refuses download of another user's conversion" do
      sign_in other
      get download_conversion_path(owned)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /conversions/log (client-side accounting)" do
    it "consumes exactly one unit and is idempotent per operation id" do
      user = create(:user, plan: :free, conversions_count: 0, confirmed_at: Time.current)
      sign_in user
      op = SecureRandom.uuid

      post log_conversions_path, params: { tool_id: "merge_pdf", operation_id: op }
      expect(response).to have_http_status(:success)
      expect(user.reload.conversions_count).to eq(1)

      # Replaying the same operation id must not double-charge.
      post log_conversions_path, params: { tool_id: "merge_pdf", operation_id: op }
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)["already_counted"]).to be true
      expect(user.reload.conversions_count).to eq(1)
    end

    it "refuses (402) when the free quota is exhausted" do
      user = create(:user, plan: :free, conversions_count: ConversionLimiter::FREE_LIMIT, confirmed_at: Time.current)
      sign_in user

      post log_conversions_path, params: { tool_id: "merge_pdf", operation_id: SecureRandom.uuid }
      expect(response).to have_http_status(:payment_required)
      expect(user.reload.conversions_count).to eq(ConversionLimiter::FREE_LIMIT)
    end

    it "rejects an unknown tool" do
      sign_in owner
      post log_conversions_path, params: { tool_id: "nope", operation_id: SecureRandom.uuid }
      expect(response).to have_http_status(:not_found)
    end
  end
end
