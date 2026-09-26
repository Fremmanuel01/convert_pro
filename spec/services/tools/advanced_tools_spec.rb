require 'rails_helper'
require 'prawn'

# These tools shell out via Open3.capture3(*argv). We stub Open3.capture3 so the
# suite does not depend on qpdf/ocrmypdf being installed, while still asserting
# that the correct binary and options are passed. The stub writes a real (valid)
# PDF to the output path so BaseTool#validate_pdf! passes as it would in prod.
RSpec.describe "Advanced Tools Logic" do
  let(:user) { create(:user) }
  let(:file) { fixture_file_upload('sample.pdf', 'application/pdf') }

  # A minimal but genuinely valid PDF, comfortably over the 100-byte guard.
  def valid_pdf_bytes
    io = StringIO.new
    Prawn::Document.new { |pdf| pdf.text "stub output" }.render(io)
    io.string
  end

  # Stub Open3.capture3 to record the argv and emit a successful result,
  # writing a valid PDF to the last argument (the output path).
  def stub_capture3(&arg_assertions)
    ok = instance_double(Process::Status, success?: true)
    allow(Open3).to receive(:capture3) do |*argv|
      arg_assertions.call(argv)
      File.binwrite(argv.last, valid_pdf_bytes)
      ["", "", ok]
    end
  end

  before do
    FileUtils.mkdir_p(Rails.root.join('spec/fixtures/files'))
    File.write(Rails.root.join('spec/fixtures/files/sample.pdf'), '%PDF-1.4 mock content')
  end

  describe Tools::ProtectPdf do
    let(:conversion) do
      Conversion.create!(user: user, tool_name: "Tools::ProtectPdf",
                         status: :pending, options: { 'password' => 'secret123' })
    end

    before { conversion.input_files.attach(file) }

    it "invokes qpdf with the encryption password from options" do
      stub_capture3 do |argv|
        expect(argv).to include("qpdf", "--encrypt", "secret123")
      end

      Tools::ProtectPdf.new(conversion).call

      conversion.reload
      expect(conversion.status).to eq("completed")
      expect(conversion.output_file).to be_attached
    end
  end

  describe Tools::OcrPdf do
    let(:conversion) do
      Conversion.create!(user: user, tool_name: "Tools::OcrPdf",
                         status: :pending, options: { 'language' => 'fra' })
    end

    before { conversion.input_files.attach(file) }

    it "invokes ocrmypdf with the configured language" do
      stub_capture3 do |argv|
        expect(argv).to include("ocrmypdf", "fra", "--force-ocr")
      end

      Tools::OcrPdf.new(conversion).call

      conversion.reload
      expect(conversion.status).to eq("completed")
      expect(conversion.output_file).to be_attached
    end
  end
end
