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
  end
end
