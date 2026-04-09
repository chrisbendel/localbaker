require "test_helper"

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  test "require_authentication! redirects when not signed in" do
    get orders_path
    assert_redirected_to new_session_path
    assert_equal "Sign in to continue.", flash[:alert]
  end

end
