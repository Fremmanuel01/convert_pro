require 'rails_helper'

RSpec.describe "Conversion status polling", type: :request do
  let(:owner) { create(:user, confirmed_at: Time.current) }
  let(:other) { create(:user, confirmed_at: Time.current) }

  it "returns the live processing frame for the owner" do
    conv = Conversion.create!(user: owner, tool_name: "Tools::CompressPdf", status: :processing)
    sign_in owner
    get status_conversion_path(conv)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('id="conversion_status"')
    expect(response.body).to include('data-poll-active-value="true"')
  end

  it "renders the completed result with download + recommendations, and stops polling" do
    conv = Conversion.create!(user: owner, tool_name: "Tools::CompressPdf", status: :completed)
    conv.output_file.attach(io: StringIO.new("%PDF-1.4" + "0" * 400), filename: "out.pdf", content_type: "application/pdf")
    sign_in owner
    get status_conversion_path(conv)

    expect(response.body).to include("Your file is ready")
    expect(response.body).to include(download_conversion_path(conv))
    expect(response.body).to include('data-poll-active-value="false"')
    expect(response.body).to include("Do more with this") # recommendations block
  end

  it "renders a graceful failure state" do
    conv = Conversion.create!(user: owner, tool_name: "Tools::CompressPdf", status: :failed,
                              error_message: "This file is password protected.")
    sign_in owner
    get status_conversion_path(conv)

    expect(response.body).to include("couldn't finish")
    expect(response.body).to include("password protected")
  end

  it "does not leak another user's conversion (IDOR)" do
    conv = Conversion.create!(user: owner, tool_name: "Tools::CompressPdf", status: :processing)
    sign_in other
    get status_conversion_path(conv)
    expect(response).to have_http_status(:not_found)
  end
end
