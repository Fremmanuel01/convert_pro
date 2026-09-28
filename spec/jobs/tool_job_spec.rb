require 'rails_helper'

RSpec.describe ToolJob, type: :job do
  let(:user) { create(:user) }

  it "discards permanent failures and retries transient ones" do
    expect(ToolJob.rescue_handlers.map(&:first)).to include("Tools::BaseTool::ExecutionError")
    expect(ToolJob.rescue_handlers.map(&:first)).to include("StandardError")
  end

  it "does nothing for a conversion that is already completed" do
    conversion = Conversion.create!(user: user, tool_name: "Tools::CompressPdf", status: :completed)
    expect(Tools::CompressPdf).not_to receive(:new)
    ToolJob.new.perform(conversion.id)
  end

  it "marks failed and does not instantiate anything for an unregistered tool name" do
    conversion = Conversion.create!(user: user, tool_name: "Tools::Evil", status: :pending)
    ToolJob.new.perform(conversion.id)
    expect(conversion.reload.status).to eq("failed")
    expect(conversion.error_message).to eq("Unknown tool.")
  end

  it "dispatches a registered tool" do
    conversion = Conversion.create!(user: user, tool_name: "Tools::CompressPdf", status: :pending)
    fake = instance_double(Tools::CompressPdf, call: true)
    expect(Tools::CompressPdf).to receive(:new).with(conversion_matching(conversion.id)).and_return(fake)
    ToolJob.new.perform(conversion.id)
  end

  # matches a Conversion by id (the job reloads it)
  def conversion_matching(id)
    satisfy { |c| c.is_a?(Conversion) && c.id == id }
  end
end
