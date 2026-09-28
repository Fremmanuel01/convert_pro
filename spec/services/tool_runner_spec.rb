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
      expect { runner.run! }.to raise_error(ToolRunner::InvalidRequestError, /doesn't look like a supported file/)
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

  describe "Server-side file signature validation" do
    def upload(bytes, filename, declared_type)
      path = Rails.root.join("tmp", filename)
      File.binwrite(path, bytes)
      Rack::Test::UploadedFile.new(path, declared_type)
    end

    let(:real_pdf)  { upload("%PDF-1.4\n#{"0" * 300}\n%%EOF", "doc.pdf", "application/pdf") }
    let(:real_png)  { upload("\x89PNG\r\n\x1a\n#{"0" * 100}", "img.png", "image/png") }
    let(:real_zip)  { upload("PK\x03\x04#{"\x00" * 60}", "doc.docx", "application/vnd.openxmlformats-officedocument.wordprocessingml.document") }
    # A Windows executable masquerading as a PDF (correct extension + declared type, wrong bytes).
    let(:spoofed_exe) { upload("MZ\x90\x00\x03#{"\x00" * 100}", "doc.pdf", "application/pdf") }

    it "accepts a genuine PDF for a PDF tool" do
      allow(ToolJob).to receive(:set).and_return(double(perform_later: true))
      expect { ToolRunner.new(free_user, "compress_pdf", [real_pdf]).run! }.not_to raise_error
    end

    it "rejects an executable spoofing a PDF content-type" do
      expect { ToolRunner.new(free_user, "compress_pdf", [spoofed_exe]).run! }
        .to raise_error(ToolRunner::InvalidRequestError, /doesn't look like a supported file/)
    end

    it "rejects a PNG sent to a PDF tool even with a plausible name" do
      png_named_pdf = upload("\x89PNG\r\n\x1a\n#{"0" * 100}", "image.pdf", "application/pdf")
      expect { ToolRunner.new(free_user, "compress_pdf", [png_named_pdf]).run! }
        .to raise_error(ToolRunner::InvalidRequestError)
    end

    it "accepts a zip-based OOXML file for a Word tool (signature equivalent)" do
      allow(ToolJob).to receive(:set).and_return(double(perform_later: true))
      expect { ToolRunner.new(free_user, "docx_to_pdf", [real_zip]).run! }.not_to raise_error
    end

    it "does not consume quota when a file is rejected" do
      expect {
        begin
          ToolRunner.new(free_user, "compress_pdf", [spoofed_exe]).run!
        rescue ToolRunner::InvalidRequestError
        end
      }.not_to change { free_user.reload.conversions_count }
    end
  end
end
