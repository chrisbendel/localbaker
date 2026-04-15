class Shop::NotificationsController < ApplicationController
  before_action :require_authentication!
  before_action :set_store

  def create
    @notification = current_user.store_notifications.find_or_create_by(store: @store)
    redirect_to shop_path(@store.slug), notice: "You’re now following this store."
  end

  def destroy
    current_user.store_notifications.where(store: @store).destroy_all
    redirect_to shop_path(@store.slug), notice: "You’re no longer following this store."
  end

  private

  def set_store
    @store = Store.find_by!(slug: params[:slug])
  end
end
