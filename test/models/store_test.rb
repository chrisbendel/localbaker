require "test_helper"

class StoreTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(email: "storetest@example.com")
  end

  test "valid store" do
    store = Store.new(
      user: @user,
      name: "Bread House",
      slug: "bread-house"
    )
    assert_predicate store, :valid?
  end

  test "requires a name" do
    store = Store.new(user: @user, slug: "no-name")
    refute store.valid?
    assert_includes store.errors[:name], "can't be blank"
  end

  test "requires a slug" do
    store = Store.new(user: @user, name: "Test Store")
    refute store.valid?
    assert_includes store.errors[:slug], "can't be blank"
  end

  test "slug must be unique" do
    Store.create!(user: @user, name: "A", slug: "unique")
    dup = Store.new(user: @user, name: "B", slug: "unique")

    refute dup.valid?
    assert_includes dup.errors[:slug], "has already been taken"
  end

  test "slug format validation" do
    store = Store.new(user: @user, name: "Test")

    valid_slugs = %w[
      bread
      bread-house
      house12
      abc-123-def
    ]

    invalid_slugs = [
      "Bread House", # space
      "bread_house", # underscore
      "bread!", # punctuation
      "bread$" # invalid symbol
    ]

    valid_slugs.each do |slug|
      store.slug = slug
      assert store.valid?, "#{slug.inspect} should be valid"
    end

    invalid_slugs.each do |slug|
      store.slug = slug
      refute store.valid?, "#{slug.inspect} should be invalid"
      assert_includes store.errors[:slug], "is invalid"
    end
  end

  test "belongs to a user" do
    store = Store.create!(user: @user, name: "A", slug: "a")

    assert_equal @user, store.user
  end

  test "has many events (dependent destroy)" do
    store = Store.create!(user: @user, name: "A", slug: "a")
    store.events.create!(name: "E1", orders_close_at: 2.hours.from_now, pickup_at: 3.days.from_now)
    store.events.create!(name: "E2", orders_close_at: 2.hours.from_now, pickup_at: 3.days.from_now)

    assert_difference("Event.count", -2) do
      store.destroy
    end
  end

  test "monetization_allowed? returns false for free users" do
    store = Store.create!(user: @user, name: "Test", slug: "test")
    assert_not store.monetization_allowed?
  end

  test "monetization_allowed? returns true for pro users" do
    @user.update!(plan: :pro)
    store = Store.create!(user: @user, name: "Test", slug: "test")
    assert store.monetization_allowed?
  end

  # --- address ---

  test "address is optional" do
    store = Store.new(user: @user, name: "Bread House", slug: "bread-house")
    store.address = nil
    assert_predicate store, :valid?
  end

  test "address normalization: full address" do
    store = Store.create!(user: @user, name: "Bread House", slug: "bread-house", address: "165 valleyfield dr colchester vt")
    assert_equal "165 Valleyfield Dr, Colchester, VT", store.address
    assert_equal "Colchester, VT", store.location_display
  end

  test "address normalization: with zip code" do
    store = Store.create!(user: @user, name: "Bread House", slug: "bread-house", address: "165 valleyfield dr colchester vt 05446")
    assert_equal "165 Valleyfield Dr, Colchester, VT 05446", store.address
    assert_equal "Colchester, VT", store.location_display
  end

  test "address normalization: already normalized" do
    store = Store.create!(user: @user, name: "Bread House", slug: "bread-house", address: "123 Main St, Portland, OR")
    assert_equal "123 Main St, Portland, OR", store.address
    assert_equal "Portland, OR", store.location_display
  end

  test "address normalization: malformed or unrecognized stays as is" do
    store = Store.create!(user: @user, name: "Bread House", slug: "bread-house", address: "Somewhere over the rainbow")
    assert_equal "Somewhere over the rainbow", store.address
    assert_equal "Somewhere over the rainbow", store.location_display
  end

  test "address normalization: city and state only stays as is (gem limitation)" do
    # StreetAddress gem returns nil for city/state only, so it remains un-normalized
    # but we now fallback to the raw string for display
    store = Store.create!(user: @user, name: "Bread House", slug: "bread-house", address: "colchester vt")
    assert_equal "colchester vt", store.address
    assert_equal "colchester vt", store.location_display
  end

  test "address normalization: handles full state names via fallback" do
    store = Store.create!(user: @user, name: "Bread House", slug: "bread-house", address: "Colchester, Vermont")
    assert_equal "Colchester, Vermont", store.address
    assert_equal "Colchester, Vermont", store.location_display
  end

  test "active_orders? checks for orders with future pickup times" do
    store = Store.create!(user: @user, name: "Test", slug: "test")

    # Create past event (no active orders)
    past_event = store.events.create!(name: "Past", orders_close_at: 2.days.ago, pickup_at: 1.day.ago)
    past_event.orders.create!(user: User.create!(email: "customer1@example.com"))

    assert_equal false, store.active_orders?

    # Create future event (should trigger active orders)
    future_event = store.events.create!(name: "Future", orders_close_at: 1.day.from_now, pickup_at: 2.days.from_now)
    future_event.orders.create!(user: User.create!(email: "customer2@example.com"))

    assert_equal true, store.active_orders?
  end

  # --- profile fields ---

  test "bio is optional and has max length" do
    store = Store.new(user: @user, name: "Test", slug: "test")

    # Empty bio should be valid
    store.bio = ""
    assert_predicate store, :valid?

    # Bio under 1000 chars should be valid
    store.bio = "a" * 999
    assert_predicate store, :valid?

    # Bio at exactly 1000 chars should be valid
    store.bio = "a" * 1000
    assert_predicate store, :valid?

    # Bio over 1000 chars should be invalid
    store.bio = "a" * 1001
    refute store.valid?
    assert store.errors[:bio].any? { |msg| msg.include?("too long") }
  end

  test "facebook_url must be a valid URL" do
    store = Store.new(user: @user, name: "Test", slug: "test")

    # Valid URLs should be accepted
    valid_urls = [
      "https://facebook.com/bakery",
      "http://facebook.com/bakery",
      "https://www.facebook.com/profile.php?id=123"
    ]

    valid_urls.each do |url|
      store.facebook_url = url
      assert store.valid?, "#{url.inspect} should be valid"
    end

    # Invalid URLs should be rejected
    invalid_urls = [
      "not a url",
      "facebook.com/bakery",
      "htp://invalid.com"
    ]

    invalid_urls.each do |url|
      store.facebook_url = url
      refute store.valid?, "#{url.inspect} should be invalid"
      assert_includes store.errors[:facebook_url], "must be a valid URL"
    end

    # Empty should be valid
    store.facebook_url = ""
    assert_predicate store, :valid?
  end

  test "website_url must be a valid URL" do
    store = Store.new(user: @user, name: "Test", slug: "test")

    # Valid URL
    store.website_url = "https://mybakery.com"
    assert_predicate store, :valid?

    # Invalid URL
    store.website_url = "not a url"
    refute store.valid?
    assert_includes store.errors[:website_url], "must be a valid URL"

    # Empty should be valid
    store.website_url = ""
    assert_predicate store, :valid?
  end

  test "paypal_url must be a valid URL" do
    store = Store.new(user: @user, name: "Test", slug: "test")

    # Valid URL
    store.paypal_url = "https://paypal.me/mybakery"
    assert_predicate store, :valid?

    # Invalid URL
    store.paypal_url = "paypal without protocol"
    refute store.valid?
    assert_includes store.errors[:paypal_url], "must be a valid URL"

    # Empty should be valid
    store.paypal_url = ""
    assert_predicate store, :valid?
  end

  test "instagram_handle format validation" do
    store = Store.new(user: @user, name: "Test", slug: "test")

    # Valid handles (with and without @)
    valid_handles = [
      "mybakery",
      "@mybakery",
      "my.bakery",
      "my_bakery",
      "my.bakery_123"
    ]

    valid_handles.each do |handle|
      store.instagram_handle = handle
      assert store.valid?, "#{handle.inspect} should be valid"
    end

    # Invalid handles
    invalid_handles = [
      "my-bakery", # dashes not allowed
      "my bakery", # spaces not allowed
      "my@bakery", # @ only valid at start
      "my!bakery" # special characters
    ]

    invalid_handles.each do |handle|
      store.instagram_handle = handle
      refute store.valid?, "#{handle.inspect} should be invalid"
      assert_includes store.errors[:instagram_handle], "should be a valid Instagram handle"
    end

    # Empty should be valid
    store.instagram_handle = ""
    assert_predicate store, :valid?
  end

  test "venmo_handle format validation" do
    store = Store.new(user: @user, name: "Test", slug: "test")

    # Valid handles (with and without @)
    valid_handles = [
      "mybakery",
      "@mybakery",
      "my-bakery",
      "my_bakery",
      "my-bakery_123"
    ]

    valid_handles.each do |handle|
      store.venmo_handle = handle
      assert store.valid?, "#{handle.inspect} should be valid"
    end

    # Invalid handles
    invalid_handles = [
      "my.bakery", # dots not allowed
      "my bakery", # spaces not allowed
      "my!bakery" # special characters
    ]

    invalid_handles.each do |handle|
      store.venmo_handle = handle
      refute store.valid?, "#{handle.inspect} should be invalid"
      assert_includes store.errors[:venmo_handle], "should be a valid Venmo handle"
    end

    # Empty should be valid
    store.venmo_handle = ""
    assert_predicate store, :valid?
  end

  test "banner_image is purged when remove_banner_image flag is set" do
    store = Store.create!(user: @user, name: "Test", slug: "test")

    # Attach a banner image
    banner_path = Rails.root.join("test/fixtures/files/banner.png")
    store.banner_image.attach(io: File.open(banner_path), filename: "banner.png", content_type: "image/png")
    assert store.banner_image.attached?

    # Update with remove_banner_image flag
    store.remove_banner_image = "1"
    store.save!

    # Banner should be purged
    refute store.banner_image.attached?
  end

  test "banner_image is not purged when remove_banner_image flag is not set" do
    store = Store.create!(user: @user, name: "Test", slug: "test")

    # Attach a banner image
    banner_path = Rails.root.join("test/fixtures/files/banner.png")
    store.banner_image.attach(io: File.open(banner_path), filename: "banner.png", content_type: "image/png")
    assert store.banner_image.attached?

    # Update without remove_banner_image flag
    store.update!(name: "Updated Name")

    # Banner should still be attached
    assert store.banner_image.attached?
  end

  test "slug cannot be changed when store has active orders" do
    store = Store.create!(user: @user, name: "Test", slug: "original")

    # Create a future event with orders
    future_event = store.events.create!(name: "Future", orders_close_at: 1.day.from_now, pickup_at: 2.days.from_now)
    future_event.orders.create!(user: User.create!(email: "customer@example.com"))

    # Verify store has active orders
    assert store.active_orders?

    # Attempt to change slug
    store.slug = "new-slug"
    refute store.valid?
    assert_includes store.errors[:slug], "cannot be changed while orders are pending"

    # Verify slug wasn't changed
    assert_equal "original", store.reload.slug
  end

  test "slug can be changed when store has no active orders" do
    store = Store.create!(user: @user, name: "Test", slug: "original")

    # Verify no active orders
    assert_not store.active_orders?

    # Change slug should be allowed
    store.slug = "new-slug"
    assert store.valid?
    store.save!
    assert_equal "new-slug", store.reload.slug
  end

  test "slug can be changed when active orders are in the past" do
    store = Store.create!(user: @user, name: "Test", slug: "original")

    # Create a past event with orders
    past_event = store.events.create!(name: "Past", orders_close_at: 2.days.ago, pickup_at: 1.day.ago)
    past_event.orders.create!(user: User.create!(email: "customer@example.com"))

    # Verify no active orders
    assert_not store.active_orders?

    # Change slug should be allowed
    store.slug = "new-slug"
    assert store.valid?
    store.save!
    assert_equal "new-slug", store.reload.slug
  end
end
