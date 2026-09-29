require 'rails_helper'

# Integration smoke test of the real server-side upload -> validate -> enqueue
# path. Uses a server-side tool (Compress PDF) and the rack_test driver so it
# runs without a browser and does not exercise the client-side JS interception.
RSpec.describe "File Uploads", type: :system do
  let(:user) { create(:user, confirmed_at: Time.current) }

  before { sign_in user }

  it "accepts a valid upload and redirects to the processing page" do
    visit tool_path("compress_pdf")

    path = Rails.root.join("tmp", "test_upload.pdf")
    File.binwrite(path, "%PDF-1.4\n% valid enough for signature detection\n" + ("0" * 200))

    attach_file "file_input", path.to_s
    click_button "Process file"

    expect(page).to have_content("being processed")
  end
end
