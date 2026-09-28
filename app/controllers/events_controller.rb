# Records a small set of CLIENT-side funnel events (things the server can't
# otherwise see, e.g. a file being selected on the homepage before any tool is
# chosen). CSRF-protected (inherited) and rate-limited (see rack_attack).
# Never accepts arbitrary event names, and never records filenames or contents.
class EventsController < ApplicationController
  ALLOWED = %w[file_selected].freeze

  def create
    name = params[:name].to_s
    return head(:unprocessable_entity) unless ALLOWED.include?(name)

    track_event(name, properties: { source: "home" })
    head :ok
  end
end
