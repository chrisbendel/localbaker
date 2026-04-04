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

  test "monetization_allowed? returns true" do
    store = Store.create!(user: @user, name: "Test", slug: "test")
    assert_equal true, store.monetization_allowed?
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
    past_event = store.events.create!(name: "Past", orders_close_at: 1.day.ago, pickup_at: 1.day.ago)
    past_event.orders.create!(user: User.create!(email: "customer1@example.com"))

    assert_equal false, store.active_orders?

    # Create future event (should trigger active orders)
    future_event = store.events.create!(name: "Future", orders_close_at: 1.day.from_now, pickup_at: 2.days.from_now)
    future_event.orders.create!(user: User.create!(email: "customer2@example.com"))

    assert_equal true, store.active_orders?
  end
end
