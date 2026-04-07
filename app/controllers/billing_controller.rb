class BillingController < ApplicationController
  before_action :require_authentication!

  def upgrade
  end

  def checkout
    checkout_session = current_user.payment_processor.checkout(
      mode: "subscription",
      line_items: [{price: stripe_pro_price_id, quantity: 1}],
      success_url: billing_success_url,
      cancel_url: billing_upgrade_url
    )
    redirect_to checkout_session.url, allow_other_host: true
  rescue => e
    Rails.logger.error("Stripe checkout error: #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
    redirect_to billing_upgrade_path, alert: "Failed to initiate checkout. Please try again."
  end

  def success
    # TODO: move subscription sync to a background job to avoid latency on this
    # user-facing redirect. Currently a safety net for the webhook delivery window.
    if (processor = current_user.payment_processor) && processor.processor_id.present?
      processor.sync_subscriptions(status: "all") unless Rails.env.test?
      current_user.pro! if processor.subscriptions.active.any?
    end
    flash.now[:notice] = "Welcome to Pro! Your subscription is now active."
  end

  def portal
    if current_user.pro?
      session = current_user.payment_processor.billing_portal(return_url: settings_account_url)
      redirect_to session.url, allow_other_host: true
    else
      redirect_to billing_upgrade_path, alert: "Upgrade to Pro first to manage your subscription."
    end
  rescue => e
    Rails.logger.error("Stripe billing portal error: #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
    redirect_to settings_account_path, alert: "Failed to open billing portal. Please try again."
  end

  private

  def stripe_pro_price_id
    ENV.fetch("STRIPE_PRO_PRICE_ID")
  end
end
