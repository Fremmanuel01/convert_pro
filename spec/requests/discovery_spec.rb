require 'rails_helper'

RSpec.describe "Discovery surfaces", type: :request do
  describe "GET / (upload-first homepage)" do
    it "renders the upload-first hero with the client tool index" do
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("What do you need to do with your file")
      expect(response.body).to include('data-controller="uploader"')
      expect(response.body).to include("data-uploader-tools-value")
      # honest trust copy — no universal "no account required" / "all in your browser"
      expect(response.body).to include("Files deleted after processing")
    end
  end

  describe "GET /tools (grouped + searchable)" do
    it "renders user-language groups, search and filter tabs" do
      get tools_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-controller="tool-filter"')
      expect(response.body).to include("PDF Tools")
      expect(response.body).to include("Scan &amp; OCR")
      expect(response.body).to include("AI Documents")
      expect(response.body).to include("Search tools")
    end
  end
end

RSpec.describe ToolRegistry, "information architecture" do
  it "assigns every registered tool to exactly one group" do
    grouped = ToolRegistry::GROUPS.values.flatten
    all_ids = ToolRegistry.tools.map { |t| t[:id] }

    expect(grouped.sort).to eq(all_ids.sort)
    expect(grouped.size).to eq(grouped.uniq.size) # no tool in two groups
  end

  it "file_tool_index excludes prompt/URL tools and includes extensions" do
    index = ToolRegistry.file_tool_index
    ids = index.map { |t| t[:id] }
    expect(ids).not_to include("ai_generate_pptx", "ai_generate_docx", "webpage_to_pdf")
    pdf_tool = index.find { |t| t[:id] == "compress_pdf" }
    expect(pdf_tool[:exts]).to include("pdf")
  end
end
