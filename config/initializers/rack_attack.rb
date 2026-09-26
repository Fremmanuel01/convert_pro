# Abuse protection. All thresholds live centrally in AppLimits::RATE_LIMITS so
# they can be tuned (via ENV) without touching this file.
#
# Strategy:
#   - Anonymous conversion traffic is throttled per IP (with a stricter bucket
#     for expensive AI/LibreOffice/OCR/headless-Chrome tools).
#   - Authenticated conversion traffic is additionally throttled per user.
#   - Auth-sensitive endpoints (sign in / sign up / password reset) per IP.
#   - The client-side accounting endpoint per IP.
class Rack::Attack
  LIMITS = AppLimits::RATE_LIMITS

  ### Cache store ------------------------------------------------------------
  # Use an isolated in-memory store in test so throttle specs are deterministic
  # and don't depend on the app cache backend.
  if Rails.env.test?
    self.cache.store = ActiveSupport::Cache::MemoryStore.new
  end

  ### Helpers ----------------------------------------------------------------
  def self.conversion_create?(req)
    req.post? && req.path == "/tools"
  end

  def self.warden_user_id(req)
    req.env["warden"]&.user&.id
  rescue StandardError
    nil
  end

  ### Safelist ----------------------------------------------------------------
  safelist("health-check") { |req| req.path == "/up" }

  ### Throttles ---------------------------------------------------------------

  # Anonymous / all: conversion submissions per IP.
  throttle("conversions/ip", limit: LIMITS[:conversions_per_ip][:limit],
                             period: LIMITS[:conversions_per_ip][:period]) do |req|
    req.ip if conversion_create?(req)
  end

  # Expensive tools per IP — a much tighter bucket.
  throttle("conversions/expensive/ip", limit: LIMITS[:expensive_per_ip][:limit],
                                       period: LIMITS[:expensive_per_ip][:period]) do |req|
    req.ip if conversion_create?(req) && AppLimits::EXPENSIVE_TOOL_IDS.include?(req.params["tool_id"])
  end

  # Authenticated: conversion submissions per user (when warden has run).
  throttle("conversions/user", limit: LIMITS[:conversions_per_user][:limit],
                               period: LIMITS[:conversions_per_user][:period]) do |req|
    warden_user_id(req) if conversion_create?(req)
  end

  # Client-side accounting endpoint per IP.
  throttle("accounting/ip", limit: LIMITS[:accounting_per_ip][:limit],
                            period: LIMITS[:accounting_per_ip][:period]) do |req|
    req.ip if req.post? && req.path == "/conversions/log"
  end

  # Login attempts per IP.
  throttle("logins/ip", limit: LIMITS[:logins_per_ip][:limit],
                        period: LIMITS[:logins_per_ip][:period]) do |req|
    req.ip if req.post? && req.path == "/users/sign_in"
  end

  # Signups per IP.
  throttle("signups/ip", limit: LIMITS[:signups_per_ip][:limit],
                         period: LIMITS[:signups_per_ip][:period]) do |req|
    req.ip if req.post? && req.path == "/users"
  end

  # Password reset requests per IP (reuse login bucket sizing).
  throttle("passwords/ip", limit: LIMITS[:logins_per_ip][:limit],
                           period: LIMITS[:logins_per_ip][:period]) do |req|
    req.ip if req.post? && req.path == "/users/password"
  end

  ### Response ----------------------------------------------------------------
  self.throttled_responder = lambda do |request|
    retry_after = (request.env["rack.attack.match_data"] || {})[:period]
    [
      429,
      { "Content-Type" => "application/json", "Retry-After" => retry_after.to_s },
      [{ error: "Too many requests. Please slow down and try again shortly." }.to_json]
    ]
  end
end

# Log throttles for observability.
ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |_name, _start, _finish, _id, payload|
  req = payload[:request]
  Rails.logger.warn("[Rack::Attack] throttled #{req.env['rack.attack.matched']} ip=#{req.ip} path=#{req.path}")
end
