require 'rails_helper'

# All AI calls are stubbed with WebMock so the suite never spends live API money.
RSpec.describe "AI tools", type: :service do
  let(:user) { create(:user) }

  describe "central provider configuration" do
    it "uses a valid Claude model id (not the old invalid 'claude-opus-4-6')" do
      expect(AiConfig::CLAUDE[:model]).to match(/\Aclaude-/)
      expect(AiConfig::CLAUDE[:model]).not_to eq("claude-opus-4-6")
    end
  end

  describe Tools::AiGeneratePptx do
    let(:conversion) do
      Conversion.create!(user: user, tool_name: "Tools::AiGeneratePptx",
                         status: :pending, options: { "prompt" => "The future of solar energy" })
    end

    def stub_claude(status:, body:)
      stub_request(:post, AiConfig::CLAUDE[:url])
        .to_return(status: status, body: body, headers: { "Content-Type" => "application/json" })
    end

    it "sends the centrally-configured model and produces a pptx" do
      slides_json = { title: "Solar", subtitle: "Energy",
                      slides: [{ title: "Intro", bullets: ["a", "b"] }] }.to_json
      stub_claude(status: 200, body: { content: [{ text: slides_json }] }.to_json)

      Tools::AiGeneratePptx.new(conversion).call

      expect(conversion.reload.status).to eq("completed")
      expect(conversion.output_file).to be_attached
      expect(WebMock).to have_requested(:post, AiConfig::CLAUDE[:url])
        .with { |req| JSON.parse(req.body)["model"] == AiConfig::CLAUDE[:model] }
    end

    it "fails gracefully (no crash, no retry) when the provider errors" do
      stub_claude(status: 500, body: { error: { message: "overloaded" } }.to_json)

      expect { Tools::AiGeneratePptx.new(conversion).call }.not_to raise_error

      expect(conversion.reload.status).to eq("failed")
      expect(conversion.error_message).to match(/Claude API error/i)
    end

    it "fails gracefully when the API key is missing" do
      allow(AiConfig).to receive(:claude_api_key).and_return(nil)
      expect { Tools::AiGeneratePptx.new(conversion).call }.not_to raise_error
      expect(conversion.reload.status).to eq("failed")
      expect(conversion.error_message).to match(/API key not configured/i)
    end
  end
end
