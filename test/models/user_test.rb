require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "normalizes email" do
    user = User.create!(email: "  Alice@Example.COM  ")
    assert_equal "alice@example.com", user.email
  end

  test "requires an email" do
    user = User.new(email: "")
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "validates email format" do
    user = User.new(email: "not-an-email")
    assert_not user.valid?
    assert_includes user.errors[:email], "is invalid"
  end

  test "enforces unique email (case insensitive)" do
    User.create!(email: "test@example.com")

    dup = User.new(email: "TEST@example.com")

    assert_not dup.valid?
    assert_includes dup.errors[:email], "has already been taken"
  end

  test "has_one :store association" do
    user = User.create!(email: "user@example.com")
    store = user.create_store!(name: "My Store", slug: "my-store")

    assert_equal store, user.store
    assert_equal user, store.user
  end

  test "destroys associated store when user is destroyed" do
    user = User.create!(email: "user@example.com")
    user.create_store!(name: "My Store", slug: "my-store")

    assert_difference -> { Store.count }, -1 do
      user.destroy
    end
  end

  # --- plan ---

  test "defaults to free plan" do
    user = User.create!(email: "baker@example.com")
    assert user.free?
    assert_not user.pro?
  end

  test "can be upgraded to pro" do
    user = User.create!(email: "baker@example.com")
    user.update!(plan: :pro)
    assert user.pro?
    assert_not user.free?
  end

  # --- at_event_limit? ---

  def create_published_event(store, pickup_at: 2.days.from_now)
    event = store.events.create!(
      name: "Event",
      orders_close_at: pickup_at - 1.hour,
      pickup_at: pickup_at
    )
    event.update_column(:published_at, Time.current)
    event
  end

  test "at_event_limit? returns false for pro user regardless of event count" do
    user = User.create!(email: "pro@example.com", plan: :pro)
    store = user.create_store!(name: "Pro Store", slug: "pro-store")
    create_published_event(store)
    assert_not user.at_event_limit?
  end

  test "at_event_limit? returns false when free user has no active events" do
    user = User.create!(email: "free@example.com")
    user.create_store!(name: "Free Store", slug: "free-store")
    assert_not user.at_event_limit?
  end

  test "at_event_limit? returns false when free user is below the limit" do
    user = User.create!(email: "free@example.com")
    store = user.create_store!(name: "Free Store", slug: "free-store")
    (User::FREE_EVENT_LIMIT - 1).times do
      create_published_event(store)
    end
    assert_not user.at_event_limit?
  end

  test "at_event_limit? returns true when free user reaches the limit" do
    user = User.create!(email: "free@example.com")
    store = user.create_store!(name: "Free Store", slug: "free-store")
    User::FREE_EVENT_LIMIT.times do
      create_published_event(store)
    end
    assert user.at_event_limit?
  end

  test "at_event_limit? does not count past events" do
    user = User.create!(email: "free@example.com")
    store = user.create_store!(name: "Free Store", slug: "free-store")
    User::FREE_EVENT_LIMIT.times do |i|
      create_published_event(store, pickup_at: (i + 1).weeks.ago)
    end
    assert_not user.at_event_limit?
  end
end
