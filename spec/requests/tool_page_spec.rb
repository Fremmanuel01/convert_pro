require 'rails_helper'

RSpec.describe "Migrated tool page", type: :request do
  it "renders options from registry data (no per-tool template branches)" do
    get tool_path("compress_pdf")
    expect(response.body).to include("Compression level")
    get tool_path("watermark_pdf")
    expect(response.body).to include("Watermark text")
    get tool_path("ai_generate_pptx")
    expect(response.body).to include("Slides")
  end

  it "has removed the legacy monolith (inline JS, CDN PDF.js, decorative preview)" do
    get tool_path("compress_pdf")
    expect(response.body).not_to include("toggleOptions")
    expect(response.body).not_to include("cdnjs.cloudflare.com/ajax/libs/pdf.js")
    expect(response.body).not_to include("settings-preview")
  end

  it "renders the right input mode per tool" do
    get tool_path("webpage_to_pdf")
    expect(response.body).to include('type="url"')
    get tool_path("ai_generate_docx")
    expect(response.body).to include("Describe what you want")
    get tool_path("compress_pdf")
    expect(response.body).to include('data-controller="file-drop"')
  end

  it "surfaces semantic search aliases in the tools index dataset" do
    get tools_path
    expect(response.body).to include("make pdf smaller")   # compress
    expect(response.body).to include("combine documents")  # merge
    expect(response.body).to include("scan to text")       # ocr
  end
end

RSpec.describe "File hand-off", type: :request do
  let(:user) { create(:user, confirmed_at: Time.current) }

  def completed_pdf_conversion(owner)
    c = Conversion.create!(user: owner, tool_name: "Tools::DocxToPdf", status: :completed)
    c.output_file.attach(io: StringIO.new("%PDF-1.4\n" + "0" * 400), filename: "report.pdf", content_type: "application/pdf")
    c
  end

  it "shows a hand-off banner when a compatible prior output is passed" do
    sign_in user
    src = completed_pdf_conversion(user)
    get tool_path("compress_pdf", from_conversion: src.id)
    expect(response.body).to include("from your last conversion")
    expect(response.body).to include("report.pdf")
  end

  it "does not offer hand-off for another user's conversion (IDOR)" do
    other = create(:user, confirmed_at: Time.current)
    src = completed_pdf_conversion(other)
    sign_in user
    get tool_path("compress_pdf", from_conversion: src.id)
    expect(response.body).not_to include("from your last conversion")
  end

  it "does not offer hand-off when the output type is incompatible" do
    sign_in user
    src = completed_pdf_conversion(user) # PDF output
    get tool_path("heic_to_jpg", from_conversion: src.id) # accepts heic, not pdf
    expect(response.body).not_to include("from your last conversion")
  end

  it "ToolRunner uses the source output as input without an upload" do
    src = completed_pdf_conversion(user)
    allow(ToolJob).to receive(:set).and_return(double(perform_later: true))
    runner = ToolRunner.new(user, "compress_pdf", [], {}, source_conversion_id: src.id)
    conversion = nil
    expect { conversion = runner.run! }.to change(Conversion, :count).by(1)
    expect(conversion.input_files.count).to eq(1)
    expect(conversion.input_files.first.filename.to_s).to eq("report.pdf")
  end
end

RSpec.describe "Commercial claim audit", type: :request do
  it "enterprise page makes no unsupported claims" do
    get enterprise_path
    body = response.body
    ["99.9%", "50k+", "Uptime SLA", "Dedicated account", "Trusted by teams", "Microsoft", "SSO", "audit logs"].each do |claim|
      expect(body).not_to include(claim), "enterprise still claims: #{claim}"
    end
    expect(body).to include("don't yet offer team accounts")
  end

  it "solutions page is reframed around jobs, no fake segment popularity or vanity counts" do
    get solutions_path
    expect(response.body).not_to match(/Join thousands/i)
    expect(response.body).not_to match(/\bPopular\b/)
    expect(response.body).not_to match(/cloud storage/i)
    expect(response.body).to include("Prepare PDFs")
  end
end

RSpec.describe "Auth screens", type: :request do
  it "sign-in and sign-up render on the design system with the Google button" do
    get new_user_session_path
    expect(response.body).to include('id="google-signin-btn"')
    expect(response.body).to include("odt-input")
    expect(response.body).not_to match(/join thousands/i)

    get new_user_registration_path
    expect(response.body).to include("Create your free account")
    expect(response.body).to include("odt-input")
  end
end
