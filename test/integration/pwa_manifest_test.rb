require "test_helper"

class PwaManifestTest < ActionDispatch::IntegrationTest
  test "serves the manifest as json" do
    get "/manifest.json"
    assert_response :success
  end

  test "does not 500 on non-json manifest extensions" do
    # Bots probe /manifest.js; the route must not match and render a
    # missing :js template (which raised ActionView::MissingTemplate → 500).
    # An unmatched route raises RoutingError, which Rails serves as a 404
    # (and Honeybadger ignores), not a reported 500.
    assert_raises(ActionController::RoutingError) { get "/manifest.js" }
  end
end
