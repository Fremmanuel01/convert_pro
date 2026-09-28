require 'rails_helper'

RSpec.describe "Funnel events", type: :request do
  describe "POST /events" do
    it "records a whitelisted client event" do
      expect { post events_path, params: { name: "file_selected" } }
        .to change(AnalyticsEvent, :count).by(1)
      expect(response).to have_http_status(:ok)
      expect(AnalyticsEvent.last.name).to eq("file_selected")
    end

    it "rejects an event name that is not whitelisted" do
      expect { post events_path, params: { name: "exfiltrate_documents" } }
        .not_to change(AnalyticsEvent, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "funnel attribution on tool views" do
    it "attributes a homepage-originated tool view" do
      get tool_path("compress_pdf", from: "home")
      ev = AnalyticsEvent.where(name: "tool_viewed").last
      expect(ev.properties["source"]).to eq("home")
    end

    it "records a next-step (recommendation) tool view" do
      get tool_path("compress_pdf", from: "next")
      ev = AnalyticsEvent.where(name: "tool_viewed").last
      expect(ev.properties["source"]).to eq("next")
    end

    it "defaults to direct for unknown sources" do
      get tool_path("compress_pdf", from: "<script>")
      ev = AnalyticsEvent.where(name: "tool_viewed").last
      expect(ev.properties["source"]).to eq("direct")
    end
  end
end
