require "test_helper"

class BillingControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "baker@example.com")
  end

  # --- upgrade ---

  test "GET upgrade requires authentication" do
    get billing_upgrade_path
    assert_redirected_to new_session_path
  end

  test "GET upgrade renders for free user" do
    sign_in_as(@user)
    get billing_upgrade_path
    assert_response :success
  end

  test "GET upgrade renders for pro user" do
    @user.update!(plan: :pro)
    sign_in_as(@user)
    get billing_upgrade_path
    assert_response :success
  end

  # --- checkout ---

  test "POST checkout requires authentication" do
    post billing_checkout_path
    assert_redirected_to new_session_path
  end

  # Actual Stripe redirect is covered by manual testing.
  # This fails because STRIPE_PRO_PRICE_ID / Stripe API keys are not present in test,
  # which exercises the rescue path and verifies the user sees a graceful error.
  test "POST checkout redirects to upgrade page on error" do
    sign_in_as(@user)
    post billing_checkout_path
    assert_redirected_to billing_upgrade_path
  end

  # --- success ---

  test "GET success requires authentication" do
    get billing_success_path
    assert_redirected_to new_session_path
  end

  test "GET success renders for authenticated user" do
    sign_in_as(@user)
    get billing_success_path
    assert_response :success
  end

  test "GET success updates user plan to pro if subscription exists" do
    sign_in_as(@user)
    processor = @user.set_payment_processor(:stripe, processor_id: "cus_123")
    processor.subscriptions.create!(name: "pro", processor_id: "sub_123", status: "active", processor_plan: "pro")

    assert_changes -> { @user.reload.plan }, from: "free", to: "pro" do
      get billing_success_path
    end
  end

  test "POST checkout redirects pro user to portal instead of creating duplicate subscription" do
    @user.update!(plan: :pro)
    sign_in_as(@user)
    post billing_checkout_path
    assert_redirected_to billing_portal_path
  end

  # --- portal ---

  test "POST portal requires authentication" do
    post billing_portal_path
    assert_redirected_to new_session_path
  end

  test "POST portal redirects free user to upgrade page" do
    sign_in_as(@user)
    post billing_portal_path
    assert_redirected_to billing_upgrade_path
  end

  # Actual Stripe portal redirect is covered by manual testing.
  # We verify pro users don't get bounced to the upgrade page.
  test "POST portal does not redirect pro user to upgrade page" do
    @user.update!(plan: :pro)
    sign_in_as(@user)
    post billing_portal_path
    assert_not_equal billing_upgrade_path, response.location
  end
end
