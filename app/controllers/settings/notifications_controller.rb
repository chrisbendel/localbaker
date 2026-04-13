module Settings
  # Manages store follow subscriptions (which bakeries a user gets notified about).
  # If we add site-wide email preferences (order confirmations, marketing, etc.),
  # add those here — likely as a separate action or a dedicated Settings::EmailPreferencesController.
  class NotificationsController < BaseController
    skip_before_action :set_store

    def index
      @notifications = current_user.store_notifications.includes(:store)
    end

    def destroy
      notification = current_user.store_notifications.find(params[:id])
      notification.destroy
      redirect_to settings_notifications_path, notice: "Unsubscribed."
    end
  end
end
