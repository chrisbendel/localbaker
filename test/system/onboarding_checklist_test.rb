require "application_system_test_case"

class OnboardingChecklistTest < ApplicationSystemTestCase
  setup do
    @baker = User.create!(email: "baker@example.com")
    @store = Store.create!(user: @baker, name: "The Crusty Loaf", slug: "crusty-loaf")
    sign_in_via_browser(@baker)
  end

  test "checklist shows for a new store with all steps incomplete" do
    visit store_path

    assert_text "Setup Checklist"
    assert_text "Add your store address and description"
    assert_text "Create your first event"
    assert_text "Add products to an event"
    assert_text "Publish and share your store"
  end

  test "checklist step 1 completes after adding address and description" do
    visit settings_store_path
    fill_in "Description", with: "Fresh sourdough every week."
    fill_in "Store Address", with: "123 Baker St, Portland, OR"
    click_on "Save Changes"

    # Settings redirect back to settings, but checklist is on dashboard
    visit store_path

    assert_text "Setup Checklist"
    assert_no_link "Add your store address and description"
  end

  test "checklist disappears once all steps are complete" do
    @store.update!(
      address: "123 Baker St, Portland, OR",
      description: "Fresh bread weekly."
    )
    event = @store.events.create!(
      name: "Saturday Bake",
      orders_close_at: 1.day.from_now,
      pickup_at: 2.days.from_now
    )
    event.event_products.create!(name: "Sourdough", quantity: 10, price_cents: 1400)
    event.update!(published_at: Time.current)

    visit store_path

    assert_no_text "Setup Checklist"
  end

  test "dismiss button hides the checklist" do
    visit store_path

    assert_text "Setup Checklist"
    click_on "Dismiss"

    assert_no_text "Setup Checklist"
  end
end
