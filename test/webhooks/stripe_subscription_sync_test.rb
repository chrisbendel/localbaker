require "test_helper"

class StripeSubscriptionSyncTest < ActiveSupport::TestCase
  FakeSubscription = Struct.new(:id, :status, keyword_init: true)
  FakeEventData = Struct.new(:object, keyword_init: true)
  FakeEvent = Struct.new(:data, keyword_init: true)

  setup do
    @user = User.create!(email: "baker@example.com")
    @user.set_payment_processor :fake_processor, allow_fake: true
    @pay_subscription = @user.payment_processor.subscribe(plan: "fake")
    @sync = StripeSubscriptionSync.new
  end

  def stripe_event(status:, id: @pay_subscription.processor_id)
    # Ensure the local pay_subscription record reflects the status change,
    # as Pay would normally handle this before our custom delegator runs.
    if (sub = @user.pay_subscriptions.find_by(processor_id: id))
      sub.update!(status: status)
    end
    FakeEvent.new(data: FakeEventData.new(object: FakeSubscription.new(id: id, status: status)))
  end

  test "sets plan to pro when subscription becomes active" do
    @user.update!(plan: :free)
    @sync.call(stripe_event(status: "active"))
    assert @user.reload.pro?
  end

  test "sets plan to free when subscription is deleted" do
    @user.update!(plan: :pro)
    @sync.call(stripe_event(status: "canceled"))
    assert @user.reload.free?
  end

  test "sets plan to free when subscription is past_due" do
    @user.update!(plan: :pro)
    @sync.call(stripe_event(status: "past_due"))
    assert @user.reload.free?
  end

  test "sets plan to free when subscription is unpaid" do
    @user.update!(plan: :pro)
    @sync.call(stripe_event(status: "unpaid"))
    assert @user.reload.free?
  end

  test "does nothing when pay subscription is not found" do
    @user.update!(plan: :pro)
    @sync.call(stripe_event(status: "canceled", id: "sub_unknown"))
    assert @user.reload.pro?
  end

  test "does not change plan for unhandled statuses" do
    @user.update!(plan: :free)
    @sync.call(stripe_event(status: "trialing"))
    assert @user.reload.free?
  end

  test "keeps plan as pro when one subscription is canceled but another remains active" do
    # Create a second active subscription for the same user
    second_subscription = @user.payment_processor.subscribe(plan: "fake")

    @user.update!(plan: :pro)

    # Cancel the first subscription — the second is still active
    @sync.call(stripe_event(status: "canceled"))

    assert @user.reload.pro?

    # Now cancel the second — no active subscriptions remain
    @sync.call(stripe_event(status: "canceled", id: second_subscription.processor_id))

    assert @user.reload.free?
  end
end
