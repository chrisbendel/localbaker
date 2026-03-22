# This controller only exists in the test environment.
# It provides a direct sign-in endpoint so system tests can authenticate
# without going through the email OTP flow (which is tested separately
# in controllers/sessions_controller_test.rb).
raise "Test::AuthController loaded outside test environment" unless Rails.env.test?

class Test::AuthController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    user = User.find(params[:user_id])
    sign_in(user)
    redirect_to dashboard_path
  end
end
