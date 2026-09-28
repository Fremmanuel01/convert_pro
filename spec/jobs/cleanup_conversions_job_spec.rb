require 'rails_helper'

RSpec.describe CleanupConversionsJob, type: :job do
  def conversion_for(user, created_at:, status: :completed, **attrs)
    c = Conversion.create!(user: user, tool_name: "Tools::CompressPdf", status: status, **attrs)
    c.update_columns(created_at: created_at, updated_at: created_at)
    c
  end

  it "purges free-user conversions past the free retention window" do
    free   = create(:user, plan: :free)
    old    = conversion_for(free, created_at: 2.days.ago)
    recent = conversion_for(free, created_at: 1.hour.ago)

    described_class.new.perform

    expect(Conversion.exists?(old.id)).to be false
    expect(Conversion.exists?(recent.id)).to be true
  end

  it "purges guest (unassigned) conversions past the guest window" do
    guest = Conversion.create!(user: nil, tool_name: "Tools::MergePdf", status: :completed)
    guest.update_columns(created_at: 2.days.ago, updated_at: 2.days.ago)

    described_class.new.perform

    expect(Conversion.exists?(guest.id)).to be false
  end

  it "keeps Pro conversions within the 30-day window" do
    pro  = create(:user, plan: :pro, subscription_status: :active)
    kept = conversion_for(pro, created_at: 10.days.ago)

    described_class.new.perform

    expect(Conversion.exists?(kept.id)).to be true
  end

  it "purges stale failed conversions quickly" do
    free   = create(:user, plan: :free)
    failed = conversion_for(free, created_at: 12.hours.ago, status: :failed)

    described_class.new.perform

    expect(Conversion.exists?(failed.id)).to be false
  end

  it "reclaims abandoned in-flight jobs and refunds their quota" do
    user  = create(:user, plan: :free, conversions_count: 2)
    stuck = Conversion.create!(user: user, tool_name: "Tools::CompressPdf", status: :processing, usage_counted: true)
    stuck.update_columns(created_at: 3.hours.ago, updated_at: 3.hours.ago)

    described_class.new.perform

    stuck.reload
    expect(stuck.status).to eq("failed")
    expect(user.reload.conversions_count).to eq(1)
  end
end
