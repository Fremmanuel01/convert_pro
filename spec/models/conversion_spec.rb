require 'rails_helper'

RSpec.describe Conversion, type: :model do
  describe "#refund_usage!" do
    it "refunds a counted unit exactly once, even if called repeatedly" do
      user = create(:user, plan: :free, conversions_count: 3)
      conversion = Conversion.create!(user: user, tool_name: "Tools::CompressPdf",
                                      status: :failed, usage_counted: true)

      expect(conversion.refund_usage!).to be true
      expect(user.reload.conversions_count).to eq(2)

      # Idempotent: a second call is a no-op (guards against double-refund on retries).
      expect(conversion.refund_usage!).to be false
      expect(user.reload.conversions_count).to eq(2)
    end

    it "does nothing when the conversion never consumed a unit" do
      user = create(:user, plan: :free, conversions_count: 1)
      conversion = Conversion.create!(user: user, tool_name: "Tools::CompressPdf",
                                      status: :failed, usage_counted: false)

      expect(conversion.refund_usage!).to be false
      expect(user.reload.conversions_count).to eq(1)
    end
  end
end
