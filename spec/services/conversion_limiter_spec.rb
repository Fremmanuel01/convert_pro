require 'rails_helper'

RSpec.describe ConversionLimiter do
  let(:basic)   { "merge_pdf" }
  let(:premium) { "ocr_pdf" }

  let(:pro_active_user)   { User.new(email: "pro@example.com", plan: :pro, subscription_status: :active) }
  let(:pro_inactive_user) { User.new(email: "inactive@example.com", plan: :pro, subscription_status: :inactive) }

  describe ".premium?" do
    it "flags AI and OCR tools as premium, basic tools as not" do
      expect(ConversionLimiter.premium?("ocr_pdf")).to be true
      expect(ConversionLimiter.premium?("summarize_pdf")).to be true
      expect(ConversionLimiter.premium?("merge_pdf")).to be false
    end
  end

  describe "#can_convert?" do
    it "always allows basic tools for a free user" do
      user = User.new(plan: :free, premium_credits_used: 9)
      expect(ConversionLimiter.new(user).can_convert?(basic)).to be true
    end

    it "allows a premium tool while the free credit remains" do
      user = User.new(plan: :free, premium_credits_used: 0)
      expect(ConversionLimiter.new(user).can_convert?(premium)).to be true
    end

    it "blocks a premium tool once the free credit is spent" do
      user = User.new(plan: :free, premium_credits_used: 1)
      expect(ConversionLimiter.new(user).can_convert?(premium)).to be false
    end

    it "allows anything for active Pro" do
      expect(ConversionLimiter.new(pro_active_user).can_convert?(premium)).to be true
    end

    it "blocks inactive (lapsed) Pro" do
      expect(ConversionLimiter.new(pro_inactive_user).can_convert?(basic)).to be false
    end

    it "allows anonymous users" do
      expect(ConversionLimiter.new(nil).can_convert?(premium)).to be true
    end
  end

  describe "#claim! (atomic)" do
    it "never blocks basic tools and does not consume premium credits" do
      user = create(:user, plan: :free)
      results = Array.new(10) { ConversionLimiter.new(user).claim!(basic) }
      expect(results).to all(be true)
      expect(user.reload.premium_credits_used).to eq(0)
    end

    it "grants exactly FREE_PREMIUM_CREDITS premium tries, then refuses" do
      user = create(:user, plan: :free)
      results = Array.new(ConversionLimiter::FREE_PREMIUM_CREDITS + 1) { ConversionLimiter.new(user).claim!(premium) }

      expect(results.count(true)).to eq(ConversionLimiter::FREE_PREMIUM_CREDITS)
      expect(results.last).to be false
      expect(user.reload.premium_credits_used).to eq(ConversionLimiter::FREE_PREMIUM_CREDITS)
    end

    it "never lets concurrent premium claims exceed the credit" do
      user = create(:user, plan: :free, premium_credits_used: ConversionLimiter::FREE_PREMIUM_CREDITS - 1)
      first  = ConversionLimiter.new(User.find(user.id)).claim!(premium)
      second = ConversionLimiter.new(User.find(user.id)).claim!(premium)

      expect([first, second]).to contain_exactly(true, false)
      expect(user.reload.premium_credits_used).to eq(ConversionLimiter::FREE_PREMIUM_CREDITS)
    end

    it "treats active Pro as unlimited without consuming credits" do
      user = create(:user, plan: :pro, subscription_status: :active)
      expect(ConversionLimiter.new(user).claim!(premium)).to be true
      expect(user.reload.premium_credits_used).to eq(0)
    end

    it "refuses inactive Pro" do
      user = create(:user, plan: :pro, subscription_status: :inactive)
      expect(ConversionLimiter.new(user).claim!(basic)).to be false
    end
  end

  describe "#refund!" do
    it "restores a premium credit for a premium tool, never below zero" do
      user = create(:user, plan: :free, premium_credits_used: 1)
      expect(ConversionLimiter.new(user).refund!(premium)).to be true
      expect(user.reload.premium_credits_used).to eq(0)
      expect(ConversionLimiter.new(user).refund!(premium)).to be false
    end

    it "refunds a basic unit against the lifetime stat counter" do
      user = create(:user, plan: :free, conversions_count: 2)
      expect(ConversionLimiter.new(user).refund!(basic)).to be true
      expect(user.reload.conversions_count).to eq(1)
    end
  end

  describe "#status_message" do
    it "returns context-appropriate messages" do
      expect(ConversionLimiter.new(pro_active_user).status_message).to include("Unlimited")
      expect(ConversionLimiter.new(pro_inactive_user).status_message).to include("inactive")

      spent = User.new(plan: :free, premium_credits_used: 1)
      expect(ConversionLimiter.new(spent).status_message(premium)).to include("AI & OCR")
    end
  end

  describe "#block_reason" do
    it "is 'ai' for premium tools and 'quota' otherwise" do
      limiter = ConversionLimiter.new(User.new(plan: :free))
      expect(limiter.block_reason(premium)).to eq("ai")
      expect(limiter.block_reason(basic)).to eq("quota")
    end
  end
end
