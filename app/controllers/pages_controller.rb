class PagesController < ApplicationController
  before_action :authenticate_user!, only: [:dashboard]

  def home
    @tool_index = ToolRegistry.file_tool_index
    @tool_groups = ToolRegistry.groups
  end

  def pricing
  end

  def solutions
  end

  def enterprise
  end

  def dashboard
    @limiter = ConversionLimiter.new(current_user)
    @recent_conversions = current_user.conversions.order(created_at: :desc).limit(5)
    @quick_tools = frequently_used_tools(current_user)
  end

  private

  # The user's most-used tools, back-filled with sensible popular defaults so
  # the quick-access row is never empty.
  def frequently_used_tools(user)
    used_ids = user.conversions.where.not(tool_name: nil)
                   .group(:tool_name).order("count_all desc").count
                   .keys.filter_map { |cn| ToolRegistry.tools.find { |t| t[:class_name] == cn }&.dig(:id) }

    defaults = %w[compress_pdf merge_pdf pdf_to_docx images_to_pdf docx_to_pdf jpg_to_png]
    (used_ids + defaults).uniq.first(6).filter_map { |id| ToolRegistry.find(id) }
  end
end
