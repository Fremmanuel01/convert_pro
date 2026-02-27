require 'rails_helper'

RSpec.describe ToolRunner do
  let(:free_user) { create(:user, plan: :free, conversions_count: 0) }
  let(:pro_user) { create(:user, plan: :pro, subscription_status: :active) }
  let(:pdf_file) { fixture_file_upload('sample.pdf', 'application/pdf') }
  let(:docx_file) { fixture_file_upload('sample.docx', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document') }

  before do
    # Create mock fixture files for testing
    FileUtils.mkdir_p(Rails.root.join('spec/fixtures/files'))
    File.write(Rails.root.join('spec/fixtures/files/sample.pdf'), '%PDF-1.4 mock content')
    File.write(Rails.root.join('spec/fixtures/files/sample.docx'), 'PK mock docx content')
  end

  describe "Validations" do
    it "rejects unsupported file types for specific tools" do
      runner = ToolRunner.new(free_user, 'merge_pdf', [docx_file])
      expect { runner.run! }.to raise_error(ToolRunner::InvalidRequestError, /Invalid file type/)
    end

    it "rejects multiple files if tool doesn't support it" do
      runner = ToolRunner.new(free_user, 'split_pdf', [pdf_file, pdf_file])
      expect { runner.run! }.to raise_error(ToolRunner::InvalidRequestError, /Multiple files not supported/)
    end

    it "blocks free users trying to upload huge files (>10MB)" do
      # Mock the size
      allow(pdf_file).to receive(:size).and_return(11.megabytes)
      runner = ToolRunner.new(free_user, 'compress_pdf', [pdf_file])
      expect { runner.run! }.to raise_error(ToolRunner::LimitExceededError, /File size limit exceeded/)
    end
  end

  describe "Execution" do
    it "increments conversion limit, creates record and enqueues job" do
      runner = ToolRunner.new(free_user, 'merge_pdf', [pdf_file, pdf_file])
      
      configured_job = instance_double(ActiveJob::ConfiguredJob)
      expect(ToolJob).to receive(:set).with(queue: :default).and_return(configured_job)
      expect(configured_job).to receive(:perform_later).once
      
      expect { runner.run! }.to change(Conversion, :count).by(1)
      
      expect(free_user.reload.conversions_count).to eq(1)
      conversion = Conversion.last
      expect(conversion.status).to eq("pending")
      expect(conversion.tool_name).to eq("Tools::MergePdf")
      expect(conversion.input_files.count).to eq(2)
    end
  end

  describe "Limiter Integration" do
    it "blocks users who have hit their limit" do
      free_user.update!(conversions_count: 5)
      runner = ToolRunner.new(free_user, 'merge_pdf', [pdf_file, pdf_file])
      
      expect { runner.run! }.to raise_error(ToolRunner::LimitExceededError, /reached your free limit/)
    end
  end
end
