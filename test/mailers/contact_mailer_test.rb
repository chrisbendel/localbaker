require "test_helper"

class ContactMailerTest < ActionMailer::TestCase
  test "feedback sends to the feedback address with submitter reply_to" do
    mail = ContactMailer.feedback(name: "Alice", email: "alice@example.com", message: "Love it!")

    assert_equal [ContactMailer::FEEDBACK_ADDRESS], mail.to
    assert_equal ["alice@example.com"], mail.reply_to
    assert_equal "LocalBaker feedback from Alice", mail.subject
    assert_match "Love it!", mail.body.encoded
  end

  test "feedback falls back to feedback address when email is blank" do
    mail = ContactMailer.feedback(name: "Alice", email: "", message: "Anonymous note")

    assert_equal [ContactMailer::FEEDBACK_ADDRESS], mail.reply_to
  end

  test "feedback ignores a malformed email instead of failing the send" do
    mail = ContactMailer.feedback(
      name: "Spammer",
      email: "sbqv@tpvbo.evc wcuvfcitqb ucc dboinbah",
      message: "spam"
    )

    assert_equal [ContactMailer::FEEDBACK_ADDRESS], mail.reply_to
  end
end
