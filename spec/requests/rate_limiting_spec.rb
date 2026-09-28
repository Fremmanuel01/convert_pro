require 'rails_helper'

# Verifies anonymous abuse is throttled. Rack::Attack uses an isolated in-memory
# store in test (see config/initializers/rack_attack.rb); we clear it per example.
RSpec.describe "Rate limiting", type: :request do
  before do
    Rack::Attack.enabled = true
    Rack::Attack.cache.store.clear
  end

  after { Rack::Attack.cache.store.clear }

  it "throttles a flood of anonymous conversion submissions from one IP with 429" do
    limit = AppLimits::RATE_LIMITS[:conversions_per_ip][:limit]

    statuses = (1..(limit + 2)).map do
      post "/tools", params: { tool_id: "compress_pdf" }
      response.status
    end

    expect(statuses).to include(429)
  end

  it "throttles login attempts from one IP" do
    limit = AppLimits::RATE_LIMITS[:logins_per_ip][:limit]

    statuses = (1..(limit + 2)).map do
      post "/users/sign_in", params: { user: { email: "x@example.com", password: "nope" } }
      response.status
    end

    expect(statuses).to include(429)
  end
end
