require 'rails_helper'

RSpec.describe Analytics do
  it "records a whitelisted event with plan/auth context" do
    user = create(:user, plan: :free)
    expect {
      Analytics.track(:conversion_started, user: user, tool_id: "merge_pdf",
                      properties: { path: "client" })
    }.to change(AnalyticsEvent, :count).by(1)

    ev = AnalyticsEvent.last
    expect(ev.name).to eq("conversion_started")
    expect(ev.tool_id).to eq("merge_pdf")
    expect(ev.plan).to eq("free")
    expect(ev.authenticated).to be true
    expect(ev.properties).to eq({ "path" => "client" })
  end

  it "ignores unknown event names" do
    expect { Analytics.track(:document_contents_leaked) }.not_to change(AnalyticsEvent, :count)
  end

  it "drops non-whitelisted properties (never stores filenames or contents)" do
    Analytics.track(:tool_viewed, tool_id: "compress_pdf",
                    properties: { filename: "my_secret_contract.pdf", text: "TOP SECRET", path: "server" })
    props = AnalyticsEvent.last.properties
    expect(props).to eq({ "path" => "server" })
    expect(props).not_to include("filename", "text")
  end

  it "never raises into the caller" do
    allow(AnalyticsEvent).to receive(:create!).and_raise(StandardError)
    expect { Analytics.track(:signup_completed) }.not_to raise_error
  end
end
