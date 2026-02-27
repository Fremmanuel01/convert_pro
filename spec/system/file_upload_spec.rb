require 'rails_helper'

RSpec.describe "File Uploads", type: :system do
  let(:user) { User.create!(email: "test_upload@example.com", password: "password") }

  before do
    driven_by(:selenium_chrome_headless)
    sign_in user
  end

  it "successfully submits the tool form" do
    visit tool_path("Tools::MergePdf")
    
    # Create the dummy file
    File.write('tmp/test_upload.pdf', "%PDF-1.4 dummy content")
    
    attach_file('files[]', 'tmp/test_upload.pdf', make_visible: true)
    
    click_button "Process Document"
    
    # Check if we were redirected to the processing page or an error page
    expect(page).to have_content("Your files are being processed")
  end
end
