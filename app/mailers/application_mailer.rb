class ApplicationMailer < ActionMailer::Base
  # Overridable so a real address is used in production, where providers often
  # require the sender to be a verified domain.
  default from: ENV.fetch("MAILER_FROM", "from@example.com")
  layout "mailer"
end
