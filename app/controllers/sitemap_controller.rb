class SitemapController < ApplicationController
  # Public XML sitemap. Lists indexable marketing + tool pages only — never
  # private/app routes (dashboard, conversions, billing, auth).
  def index
    host = ENV.fetch("CANONICAL_HOST", "https://officedoctools.com").chomp("/")

    @entries = []
    @entries << ["#{host}/",           "daily",   "1.0"]
    @entries << ["#{host}/tools",      "weekly",  "0.9"]
    @entries << ["#{host}/pricing",    "monthly", "0.8"]
    @entries << ["#{host}/solutions",  "monthly", "0.7"]
    @entries << ["#{host}/enterprise", "monthly", "0.6"]
    ToolRegistry.tools.each do |t|
      @entries << ["#{host}/tools/#{t[:id]}", "weekly", "0.8"]
    end

    render formats: :xml
  end
end
