require 'rails_helper'

RSpec.describe "Advanced Tools Logic" do
  let(:user) { create(:user) }
  let(:conversion) { Conversion.create!(user: user, tool_name: "Tools::ProtectPdf", status: :pending, options: { 'password' => 'secret123' }) }
  let(:file) { fixture_file_upload('sample.pdf', 'application/pdf') }

  before do
    FileUtils.mkdir_p(Rails.root.join('spec/fixtures/files'))
    File.write(Rails.root.join('spec/fixtures/files/sample.pdf'), '%PDF mock content')
    conversion.input_files.attach(file)
  end

  describe Tools::ProtectPdf do
    it "invokes qpdf securely passing the options password" do
      tool = Tools::ProtectPdf.new(conversion)

      # We mock the system call to avoid requiring binary on CI immediately
      expect(tool).to receive(:system) do |command|
        expect(command).to include("qpdf")
        expect(command).to include("secret123")
        
        # Simulate successful binary output
        File.write(command.split.last, "Encrypted Mock")
        true
      end

      tool.call
      
      conversion.reload
      expect(conversion.status).to eq("completed")
      expect(conversion.output_file).to be_attached
    end
  end

  describe Tools::OcrPdf do
    let(:ocr_conversion) { Conversion.create!(user: user, tool_name: "Tools::OcrPdf", status: :pending, options: { 'language' => 'fra' }) }
    
    before do
      ocr_conversion.input_files.attach(file)
    end

    it "invokes ocrmypdf with language configuration" do
      tool = Tools::OcrPdf.new(ocr_conversion)

      expect(tool).to receive(:system) do |command|
        expect(command).to include("ocrmypdf")
        expect(command).to include("fra")
        expect(command).to include("--force-ocr")
        
        File.write(command.split.last, "OCR Mock")
        true
      end

      tool.call
      
      ocr_conversion.reload
      expect(ocr_conversion.status).to eq("completed")
    end
  end
end
