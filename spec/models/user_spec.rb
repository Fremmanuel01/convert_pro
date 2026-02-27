require 'rails_helper'

RSpec.describe User, type: :model do
  describe "validations" do
    it "requires an email" do
      user = User.new(password: "password")
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("can't be blank")
    end

    it "requires a password" do
      user = User.new(email: "test@example.com")
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("can't be blank")
    end

    it "validates conversions_count is >= 0" do
      user = User.new(email: "test@example.com", password: "password", conversions_count: -1)
      expect(user).not_to be_valid
      expect(user.errors[:conversions_count]).to include("must be greater than or equal to 0")
    end
  end

  describe "defaults" do
    it "defaults to free plan" do
      user = User.new
      expect(user.plan).to eq("free")
      expect(user.free?).to be true
    end

    it "defaults conversions_count to 0" do
      user = User.new
      expect(user.conversions_count).to eq(0)
    end

    it "defaults subscription_status to inactive" do
      user = User.new
      expect(user.subscription_status).to eq("inactive")
      expect(user.inactive?).to be true
    end
  end
end
