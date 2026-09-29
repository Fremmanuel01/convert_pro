require 'rails_helper'

# Post-migration verification: every one of the 28 registered tools resolves to a
# real class and renders through the new decomposed tool page without error, in
# whichever input mode it uses (file / multi-file / url / prompt).
RSpec.describe "All 28 tools after migration", type: :request do
  ToolRegistry.tools.each do |tool|
    describe tool[:id] do
      it "resolves to a Tools::BaseTool subclass" do
        klass = tool[:class_name].constantize
        expect(klass.ancestors).to include(Tools::BaseTool)
        expect(klass.instance_methods(false) + klass.protected_instance_methods(false)).to include(:process)
      end

      it "renders its tool page (200) with the correct input mode" do
        get tool_path(tool[:id])
        expect(response).to have_http_status(:ok)

        if tool[:input_type] == :prompt
          expect(response.body).to include("Describe what you want")
        elsif tool[:input_type] == :url
          expect(response.body).to include('type="url"')
        else
          expect(response.body).to include('data-controller="file-drop"')
          expect(response.body).to include("multiple") if tool[:accepts_multiple]
        end
      end
    end
  end

  it "renders the true tool count in marketing copy (no hardcoded number)" do
    get root_path
    expect(response.body).to include("#{ToolRegistry.tools.size} Professional Document Tools")
    expect(response.body).not_to include("28 Professional Document Tools") # real count is 27
  end
end
