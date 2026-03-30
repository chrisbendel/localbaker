require "application_system_test_case"

class StorefrontLocationTest < ApplicationSystemTestCase
  setup do
    @baker = User.create!(email: "baker@example.com")
    @store = Store.create!(
      user: @baker,
      name: "The Crusty Loaf",
      slug: "crusty-loaf",
      address: "165 valleyfield dr colchester vt"
    )
  end

  test "displaying city and state on storefront" do
    visit storefront_path(@store.slug)

    assert_text "The Crusty Loaf"
    assert_text "Colchester, VT"
    # Ensure the address in the DB was normalized too
    assert_equal "165 Valleyfield Dr, Colchester, VT", @store.reload.address
  end
end
