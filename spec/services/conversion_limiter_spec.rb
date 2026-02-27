require 'rails_helper'

RSpec.describe ConversionLimiter do
  let(:free_user) { User.new(email: "free@example.com", plan: :free, conversions_count: 0) }
  let(:pro_active_user) { User.new(email: "pro@example.com", plan: :pro, subscription_status: :active) }
  let(:pro_inactive_user) { User.new(email: "inactive@example.com", plan: :pro, subscription_status: :inactive) }

  describe "#can_convert?" do
    it "allows free user under limit" do
      limiter = ConversionLimiter.new(free_user)
      expect(limiter.can_convert?).to be true
    end

    it "blocks free user at limit" do
      free_user.conversions_count = 5
      limiter = ConversionLimiter.new(free_user)
      expect(limiter.can_convert?).to be false
    end

    it "allows pro user with active subscription" do
      limiter = ConversionLimiter.new(pro_active_user)
      expect(limiter.can_convert?).to be true
    end

    it "blocks pro user with inactive subscription" do
      limiter = ConversionLimiter.new(pro_inactive_user)
      expect(limiter.can_convert?).to be false
    end
  end

  describe "#remaining" do
    it "returns :unlimited for active pro user" do
      limiter = ConversionLimiter.new(pro_active_user)
      expect(limiter.remaining).to eq(:unlimited)
    end

    it "returns correct number for free user" do
      free_user.conversions_count = 2
      limiter = ConversionLimiter.new(free_user)
      expect(limiter.remaining).to eq(3)
    end

    it "returns 0 when limit reached" do
      free_user.conversions_count = 6
      limiter = ConversionLimiter.new(free_user)
      expect(limiter.remaining).to eq(0)
    end
  end

  describe "#increment!" do
    it "increments count if allowed (saves to DB)", :aggregate_failures do
      free_user.save!(validate: false)
      limiter = ConversionLimiter.new(free_user)
      
      expect { limiter.increment! }.to change { free_user.reload.conversions_count }.by(1)
      expect(limiter.increment!).to be true
    end

    it "does not increment if blocked" do
      free_user.conversions_count = 5
      limiter = ConversionLimiter.new(free_user)
      
      expect { limiter.increment! }.not_to change { free_user.conversions_count }
      expect(limiter.increment!).to be false
    end
  end

  describe "#status_message" do
    it "returns appropriate messages" do
      expect(ConversionLimiter.new(pro_active_user).status_message).to include("Unlimited")
      expect(ConversionLimiter.new(pro_inactive_user).status_message).to include("inactive")
      
      free_user.conversions_count = 5
      expect(ConversionLimiter.new(free_user).status_message).to include("limit")
      
      free_user.conversions_count = 2
      expect(ConversionLimiter.new(free_user).status_message).to include("3 free conversions")
    end
  end
end
