class ApplicationController < ActionController::Base

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :analytics_anonymous_id

  # After a successful sign-up, flag a one-shot client-side conversion event
  # (GA4 sign_up / Meta CompleteRegistration) fired by shared/_analytics.
  def after_sign_up_path_for(resource)
    session[:fire_signup] = true
    super
  end

  private

  # Stable, non-PII identifier scoped to the browser session. Used to stitch
  # anonymous funnel events without tracking the person across sessions.
  def analytics_anonymous_id
    session[:anon_id] ||= SecureRandom.uuid
  end

  def track_event(name, tool_id: nil, properties: {})
    Analytics.track(
      name,
      user:         current_user,
      anonymous_id: analytics_anonymous_id,
      tool_id:      tool_id,
      properties:   properties
    )
  end
end
