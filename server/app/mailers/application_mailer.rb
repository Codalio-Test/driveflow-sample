# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch('DRIVEFLOW_MAIL_FROM', 'no-reply@driveflow.example.com')
  layout false
end
