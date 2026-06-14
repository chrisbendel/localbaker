class ContactMailer < ApplicationMailer
  FEEDBACK_ADDRESS = "chrissbendel@gmail.com"

  def feedback(name:, email:, message:)
    @name = name.presence || "Anonymous"
    @email = email
    @message = message

    mail(
      to: FEEDBACK_ADDRESS,
      reply_to: valid_email?(email) ? email : FEEDBACK_ADDRESS,
      subject: "LocalBaker feedback#{" from #{@name}" if name.present?}"
    )
  end

  private

  # Submitter-supplied; only trust it as a reply_to if it's a real address,
  # otherwise Resend rejects the whole send (e.g. spam with garbage in the field).
  def valid_email?(email)
    email.present? && email.match?(URI::MailTo::EMAIL_REGEXP)
  end
end
