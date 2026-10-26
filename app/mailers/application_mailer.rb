class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "OfficedocTools <noreply@officedoctools.com>")
  layout "mailer"
end
