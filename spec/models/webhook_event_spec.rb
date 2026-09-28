require 'rails_helper'

RSpec.describe WebhookEvent, type: :model do
  it "persists a processed webhook" do
    event = WebhookEvent.create!(event_id: "evt_1", event_type: "charge.success", processed_at: Time.current)
    expect(event).to be_persisted
  end

  it "enforces unique event ids at the database level (webhook idempotency)" do
    WebhookEvent.create!(event_id: "evt_dup", event_type: "charge.success", processed_at: Time.current)
    expect {
      WebhookEvent.create!(event_id: "evt_dup", event_type: "charge.success", processed_at: Time.current)
    }.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
