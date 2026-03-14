module Admin
  class DashboardController < BaseController
    def index
      now = Time.current

      # ── User stats ──────────────────────────────────────────────
      @total_users       = User.count
      @users_today       = User.where(created_at: now.beginning_of_day..).count
      @users_this_week   = User.where(created_at: 7.days.ago..).count
      @users_this_month  = User.where(created_at: 30.days.ago..).count
      @confirmed_users   = User.where.not(confirmed_at: nil).count
      @unconfirmed_users = User.where(confirmed_at: nil).count
      @google_users      = User.where(provider: "google_oauth2").count
      @email_users       = User.where(provider: nil).count
      @pro_users         = User.where(plan: :pro).count
      @free_users        = User.where(plan: :free).count

      # ── Conversion stats ────────────────────────────────────────
      @total_conversions     = Conversion.count
      @conversions_today     = Conversion.where(created_at: now.beginning_of_day..).count
      @conversions_this_week = Conversion.where(created_at: 7.days.ago..).count
      @completed_conversions = Conversion.where(status: :completed).count
      @failed_conversions    = Conversion.where(status: :failed).count

      # ── Top tools (last 30 days) ─────────────────────────────────
      @top_tools = Conversion
        .where(created_at: 30.days.ago..)
        .group(:tool_name)
        .order("count_all DESC")
        .limit(10)
        .count

      # ── Conversions per day (last 30 days) ───────────────────────
      @conversions_by_day = Conversion
        .where(created_at: 30.days.ago..)
        .group("DATE(created_at)")
        .order("DATE(created_at)")
        .count

      # ── New users per day (last 30 days) ─────────────────────────
      @users_by_day = User
        .where(created_at: 30.days.ago..)
        .group("DATE(created_at)")
        .order("DATE(created_at)")
        .count

      # ── Recent activity ──────────────────────────────────────────
      @recent_users       = User.order(created_at: :desc).limit(10)
      @recent_conversions = Conversion.includes(:user).order(created_at: :desc).limit(10)
    end
  end
end
