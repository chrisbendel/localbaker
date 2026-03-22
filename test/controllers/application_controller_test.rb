require "test_helper"

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  test "require_authentication! redirects when not signed in" do
    get dashboard_path
    assert_redirected_to new_session_path
    assert_equal "Sign in to continue.", flash[:alert]
  end

  test "authenticated user can access dashboard" do
    user = User.create!(email: "test@example.com")
    ActionMailer::Base.deliveries.clear
    post session_path, params: {email: user.email} # creates login_code + sets login_email
    mail = ActionMailer::Base.deliveries.last
    body_text = [mail.subject, mail.text_part&.body&.to_s, mail.html_part&.body&.to_s, mail.body&.to_s].compact.join("\n")
    code = body_text[/\b\d{6}\b/]

    # Simulate successful login with code from email:
    post confirm_session_path, params: {email: user.email, code: code}

    get dashboard_path
    assert_response :success
  end
end
