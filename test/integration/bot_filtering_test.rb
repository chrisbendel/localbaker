require "test_helper"

class BotFilteringTest < ActionDispatch::IntegrationTest
  test "blocks common wordpress paths" do
    paths = [
      "/wp-admin/setup-config.php",
      "/wordpress/wp-admin/setup-config.php",
      "/wp-login.php",
      "/wp-content/plugins/wp-config.php",
      "/somepath/shell.php"
    ]

    paths.each do |path|
      get path
      assert_response :forbidden, "Expected #{path} to be blocked by Rack::Attack (403 Forbidden)"
    end
  end

  test "allows legitimate paths" do
    # Assuming there's a home page at root
    get "/"
    assert_response :success
  end
end
