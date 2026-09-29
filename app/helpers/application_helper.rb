module ApplicationHelper
  # The real number of tools, rendered from the registry so marketing copy can
  # never drift from what actually exists.
  def tool_count
    ToolRegistry.tools.size
  end
end
