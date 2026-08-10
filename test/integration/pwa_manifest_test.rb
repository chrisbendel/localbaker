require "test_helper"

class PwaManifestTest < ActionDispatch::IntegrationTest
  test "serves the manifest as json" do
    get "/manifest.json"
    assert_response :success
  end

  test "does not 500 on non-json manifest extensions" do
    # Bots probe /manifest.js. The format constraint keeps the route from
    # matching, so this is an unmatched path — a 404, not the
    # ActionView::MissingTemplate → 500 it used to be.
    get "/manifest.js"
    assert_response :not_found
  end
end
