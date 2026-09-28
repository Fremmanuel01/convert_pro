require 'rails_helper'

RSpec.describe ToolRecommender do
  def conversion_with_output(filename, content_type, tool_name: "Tools::CompressPdf")
    c = Conversion.create!(tool_name: tool_name, status: :completed)
    c.output_file.attach(io: StringIO.new("x" * 300), filename: filename, content_type: content_type)
    c
  end

  it "recommends PDF tools for a PDF output and excludes the tool that ran" do
    conv = conversion_with_output("out.pdf", "application/pdf", tool_name: "Tools::CompressPdf")
    ids = ToolRecommender.for(conv).map { |t| t[:id] }

    expect(ids).to be_present
    expect(ids).not_to include("compress_pdf")
    ids.each { |id| expect(ToolRegistry.find(id)[:accepted_types]).to include("application/pdf") }
  end

  it "recommends image tools for a JPG output" do
    conv = conversion_with_output("out.jpg", "image/jpeg", tool_name: "Tools::PdfToImages")
    ids = ToolRecommender.for(conv).map { |t| t[:id] }
    expect(ids).to include("images_to_pdf").or include("jpg_to_png")
  end

  it "never returns dead recommendations for a zip output (no tool accepts zip)" do
    conv = conversion_with_output("pages.zip", "application/zip", tool_name: "Tools::SplitPdf")
    expect(ToolRecommender.for(conv)).to eq([])
  end

  it "returns nothing when there is no output yet" do
    conv = Conversion.create!(tool_name: "Tools::CompressPdf", status: :processing)
    expect(ToolRecommender.for(conv)).to eq([])
  end

  it "respects the limit" do
    conv = conversion_with_output("out.pdf", "application/pdf", tool_name: "Tools::CompressPdf")
    expect(ToolRecommender.for(conv, limit: 2).size).to be <= 2
  end
end
