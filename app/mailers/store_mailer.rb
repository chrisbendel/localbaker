class StoreMailer < ApplicationMailer
  def confirm_subscription(store, email, token)
    @store = store
    @confirm_url = confirm_shop_notification_url(store.slug, token: token)

    mail(
      to: email,
      from: "#{store.name} <noreply@localbaker.app>",
      subject: "Confirm your subscription to #{store.name}"
    )
  end

  def new_event(store, event, notification)
    @store = store
    @event = event
    @unsubscribe_url = unsubscribe_url(token: notification.unsubscribe_token)

    mail(
      to: notification.user.email,
      from: "#{store.name} <noreply@localbaker.app>",
      subject: "#{store.name} has a new event available"
    )
  end
end
