# Minimal, privacy-preserving product analytics.
#
# Records funnel events to the analytics_events table. It deliberately stores
# NO document contents and NO filenames — only the tool involved, the
# free/paid/anonymous context, and a small whitelist of non-sensitive
# properties. Tracking never raises into the caller: a failure here must never
# break a conversion or a checkout.
class Analytics
  EVENTS = %w[
    tool_viewed
    file_selected
    conversion_started
    conversion_succeeded
    conversion_failed
    result_downloaded
    signup_completed
    quota_reached
    upgrade_viewed
    checkout_started
    subscription_activated
  ].freeze

  # Only these property keys are ever persisted. Anything else is dropped, so a
  # caller can never accidentally leak a filename or document text.
  SAFE_PROPERTY_KEYS = %i[
    source path processing tool_category file_count size_bucket
    reason billing_cycle currency amount_minor result_kind provider
  ].freeze

  def self.track(name, user: nil, anonymous_id: nil, tool_id: nil, properties: {})
    name = name.to_s
    return unless EVENTS.include?(name)

    AnalyticsEvent.create!(
      name:          name,
      user_id:       user&.id,
      anonymous_id:  anonymous_id.presence,
      tool_id:       tool_id.presence,
      plan:          user&.plan,
      authenticated: user.present?,
      properties:    sanitize(properties),
      created_at:    Time.current
    )
  rescue => e
    Rails.logger.warn("Analytics.track(#{name}) failed: #{e.message}")
    nil
  end

  def self.sanitize(properties)
    (properties || {}).symbolize_keys.slice(*SAFE_PROPERTY_KEYS)
  end

  # Bucket a byte size into coarse ranges so we never store exact file sizes
  # that could correlate to a specific document.
  def self.size_bucket(bytes)
    mb = bytes.to_f / 1.megabyte
    case mb
    when 0...1   then "<1MB"
    when 1...5   then "1-5MB"
    when 5...10  then "5-10MB"
    when 10...50 then "10-50MB"
    else              ">50MB"
    end
  end
end
