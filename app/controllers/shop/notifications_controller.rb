class Shop::NotificationsController < ApplicationController
  before_action :require_authentication!, only: [:destroy]
  before_action :set_store

  # Sole spam control on the public email-capture endpoint (per-IP). Sized
  # for a post-class rush behind one gym wifi IP while capping how many
  # confirmation emails a script can trigger. Submissions write nothing to
  # the database — a subscription only exists once its token is redeemed.
  rate_limit to: 5, within: 10.minutes, only: :create,
    with: -> { redirect_to shop_path(params[:slug]), alert: "Too many signups from this network — try again in a few minutes." }

  # Email-capture page for logged-out visitors. Signed-in users have the
  # one-click button on the store page instead.
  def new
    redirect_to shop_path(@store.slug) if current_user
  end

  def create
    if current_user
      current_user.store_notifications.find_or_create_by(store: @store)
      redirect_to shop_path(@store.slug), notice: "You’re now following this store."
    else
      create_from_email
    end
  end

  # Confirmation link from the email. Redeeming the token creates the
  # subscription and proves inbox ownership, so it also signs the user in
  # (same trust level as the OTP flow).
  def confirm
    notification = StoreNotification.redeem_confirmation_token(params[:token])

    if notification
      sign_in(notification.user)
      redirect_to shop_path(notification.store.slug), notice: "You’re subscribed! We’ll email you when #{notification.store.name} posts a new bake."
    else
      redirect_to new_shop_notification_path(@store.slug), alert: "That confirmation link is invalid or expired. Enter your email to get a new one."
    end
  end

  def destroy
    current_user.store_notifications.where(store: @store).destroy_all
    redirect_to shop_path(@store.slug), notice: "You’re no longer following this store."
  end

  private

  def set_store
    @store = Store.find_by!(slug: params[:slug])
  end

  def create_from_email
    email = params[:email].to_s.strip.downcase

    unless URI::MailTo::EMAIL_REGEXP.match?(email)
      flash.now[:alert] = "Enter a valid email address."
      return render :new, status: :unprocessable_entity
    end

    token = StoreNotification.generate_confirmation_token(email: email, store: @store)
    StoreMailer.confirm_subscription(@store, email, token).deliver_later

    redirect_to shop_path(@store.slug), notice: "Almost there — check your email for a confirmation link."
  end
end
