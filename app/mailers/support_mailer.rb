class SupportMailer < ApplicationMailer
  def ticket(user:, subject:, message:)
    @user    = user
    @subject = subject
    @message = message

    mail to:       "support@northbolt.co.uk",
         reply_to: user.email,
         subject:  "[Support] #{subject}"
  end
end
