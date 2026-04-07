class StripeSubscriptionSync
  def call(event)
    subscription = event.data.object
    pay_subscription = Pay::Subscription.find_by(processor_id: subscription.id)
    return unless pay_subscription

    user = pay_subscription.customer.owner
    return unless user.is_a?(User)

    resolved_plan = active_subscription?(user) ? :pro : :free
    user.update!(plan: resolved_plan)
    Rails.logger.info(
      "User #{user.id} synced to #{resolved_plan} after #{subscription.status} " \
      "(subscription: #{subscription.id})"
    )
  end

  private

  def active_subscription?(user)
    user.pay_subscriptions.where(status: "active").exists?
  end
end
