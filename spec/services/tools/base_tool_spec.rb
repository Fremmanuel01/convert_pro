require 'rails_helper'

RSpec.describe Tools::BaseTool do
  class DummyTool < Tools::BaseTool
    # Must exceed BaseTool's 100-byte empty-output guard.
    CONTENT = ("Processed content. " * 8).freeze

    protected

    def process(input_paths)
      output_path = tmp_path("test_output.txt")
      File.write(output_path, CONTENT)
      output_path
    end
  end

  class FailingTool < Tools::BaseTool
    protected

    def process(input_paths)
      raise StandardError, "Oops something broke"
    end
  end

  class PermanentFailTool < Tools::BaseTool
    protected

    def process(input_paths)
      raise Tools::BaseTool::ExecutionError, "This file is password protected."
    end
  end

  let(:user) { create(:user) }
  let(:conversion) { Conversion.create!(user: user, tool_name: "DummyTool", status: :pending) }
  let(:file) { fixture_file_upload('sample.pdf', 'application/pdf') }

  before do
    FileUtils.mkdir_p(Rails.root.join('spec/fixtures/files'))
    File.write(Rails.root.join('spec/fixtures/files/sample.pdf'), '%PDF-1.4 mock content')
    conversion.input_files.attach(file)
  end

  describe "#call" do
    it "processes and attaches output successfully" do
      tool = DummyTool.new(conversion)
      
      expect { tool.call }.not_to raise_error

      conversion.reload
      expect(conversion.status).to eq("completed")
      expect(conversion.processing_time).to be > 0.0
      expect(conversion.output_file).to be_attached
      expect(conversion.output_file.download).to eq(DummyTool::CONTENT)
    end

    it "handles failures safely" do
      failing_conversion = Conversion.create!(user: user, tool_name: "FailingTool", status: :pending)
      failing_tool = FailingTool.new(failing_conversion)
      
      expect { failing_tool.call }.to raise_error(StandardError, "Oops something broke")

      failing_conversion.reload
      expect(failing_conversion.status).to eq("failed")
      expect(failing_conversion.error_message).to include("Oops something broke")
      expect(failing_conversion.output_file).not_to be_attached
    end

    it "does NOT re-raise permanent (ExecutionError) failures — so they are not retried" do
      conv = Conversion.create!(user: user, tool_name: "PermanentFailTool", status: :pending, usage_counted: true)
      conv.input_files.attach(file)
      user.update!(conversions_count: 3)

      expect { PermanentFailTool.new(conv).call }.not_to raise_error

      expect(conv.reload.status).to eq("failed")
      expect(conv.error_message).to include("password protected")
      # Permanent failure refunds the quota unit so the user isn't charged for it.
      expect(user.reload.conversions_count).to eq(2)
    end

    it "does NOT refund on transient failures (they will be retried)" do
      conv = Conversion.create!(user: user, tool_name: "FailingTool", status: :pending, usage_counted: true)
      conv.input_files.attach(file)
      user.update!(conversions_count: 3)

      expect { FailingTool.new(conv).call }.to raise_error(StandardError, "Oops something broke")
      expect(user.reload.conversions_count).to eq(3)
    end
  end
end
