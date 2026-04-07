class StripeSubscriptionSync
  def call(event)
    subscription = event.data.object
    pay_subscription = Pay::Subscription.find_by(processor_id: subscription.id)
    return unless pay_subscription

    user = pay_subscription.customer.owner
    return unless user.is_a?(User)

    case subscription.status
    when "active"
      user.update!(plan: :pro)
      Rails.logger.info("User #{user.id} synced to pro (subscription: #{subscription.id})")
    when "past_due", "unpaid", "incomplete_expired", "canceled"
      user.update!(plan: :free)
      Rails.logger.info("User #{user.id} synced to free (status: #{subscription.status})")
    end
  end
end
