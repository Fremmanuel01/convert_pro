class AnalyticsController < ApplicationController
  before_action :authenticate_user!

  def index
    # Gather statistics for the current user's conversions
    @total_conversions = current_user.conversions.count

    # Calculate month-over-month growth (simplified example logic)
    # In a real app, this would query based on timestamps
    @recent_conversions = current_user.conversions.where('created_at > ?', 30.days.ago).count
    @older_conversions = current_user.conversions.where('created_at BETWEEN ? AND ?', 60.days.ago, 30.days.ago).count
    
    @growth_rate = if @older_conversions > 0
      (((@recent_conversions - @older_conversions).to_f / @older_conversions) * 100).round(1)
    else
      @recent_conversions > 0 ? 100.0 : 0.0
    end

    # Fetch recent activity (last 5 conversions or actions)
    @recent_activity = current_user.conversions.order(created_at: :desc).limit(5)
  end
end
