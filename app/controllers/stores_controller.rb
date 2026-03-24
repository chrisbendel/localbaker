class StoresController < ApplicationController
  before_action :require_authentication!
  before_action :set_store
  before_action :ensure_no_store!, only: [:new, :create]
  before_action :ensure_store_exists!, only: [:show, :edit, :update, :destroy]
  before_action :prevent_edit_when_locked, only: [:edit, :update, :destroy]

  def new
    @store = current_user.build_store
    # unless current_user.subscription_active?
    #   redirect_to pricing_path, alert: "A subscription is required to create a store."
    # end
  end

  def create
    @store = current_user.build_store(store_params)
    if @store.save
      redirect_to store_path, notice: "Store created!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  def edit
  end

  def update
    if params[:store][:remove_banner_image] == "1"
      @store.banner_image.purge
    end

    if @store.update(store_params)
      redirect_to store_path, notice: "Store updated!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @store.destroy
    redirect_to dashboard_path, notice: "Store removed."
  end

  private

  def set_store
    @store = current_user.store
  end

  def ensure_no_store!
    redirect_to store_path, alert: "You already have a store." if @store
  end

  def ensure_store_exists!
    redirect_to new_store_path, alert: "Create your store first." unless @store
  end

  def prevent_edit_when_locked
    if @store.active_orders?
      redirect_to store_path, alert: "Store settings are locked while you have active orders."
    end
  end

  def store_params
    params.require(:store).permit(:name, :slug, :description, :banner_image)
  end
end
