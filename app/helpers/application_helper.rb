module ApplicationHelper
  # The real number of tools, rendered from the registry so marketing copy can
  # never drift from what actually exists.
  def tool_count
    ToolRegistry.tools.size
  end

  # Conversion events a page wants fired into GA4 / Meta Pixel on load. Pages
  # call track_conversion(...); shared/_analytics renders them. Kept tiny and
  # declarative so templates never hand-roll gtag/fbq calls.
  def tracked_conversions
    @tracked_conversions ||= []
  end

  def track_conversion(ga: nil, fb: nil, params: {})
    tracked_conversions << { ga: ga, fb: fb, params: params }
  end
end
