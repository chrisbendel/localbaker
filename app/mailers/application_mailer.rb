class ApplicationMailer < ActionMailer::Base
  default from: "LocalBaker <noreply@localbaker.app>"
  layout "mailer"
  helper :application
end
