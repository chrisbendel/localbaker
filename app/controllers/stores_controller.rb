class StoresController < ApplicationController
  before_action :require_authentication!
  before_action :set_store
  before_action :ensure_no_store!, only: [:new, :create]
  before_action :ensure_store_exists!, only: [:show, :edit, :update, :destroy, :qr]

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
    @drafts = @store.events.draft.includes(:event_products).order(pickup_at: :asc)
    @upcoming = @store.events.published.where("pickup_at >= ?", Time.current).includes(:orders).order(pickup_at: :asc)
    @live = @upcoming.select(&:orders_open?)
    @prep = @upcoming.select(&:orders_closed?)
    @past = @store.events.published.where("pickup_at < ?", Time.current).order(pickup_at: :desc)
  end

  def edit
    @storefront_url = storefront_url(@store.slug)
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

  def qr
    return redirect_to billing_upgrade_path, alert: "QR codes are a Pro feature. Upgrade to unlock." if current_user.free?

    @storefront_url = storefront_url(@store.slug)
    @qr_svg = RQRCode::QRCode.new(@storefront_url).as_svg(
      color: "000",
      shape_rendering: "crispEdges",
      module_size: 6,
      standalone: true,
      use_path: true
    )
    render layout: "qr"
  end

  def dismiss_onboarding
    session[:onboarding_dismissed] = true
    redirect_to store_path
  end

  def destroy
    @store.destroy
    redirect_to root_path, notice: "Store removed."
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

  def store_params
    params.require(:store).permit(
      :name, :slug, :description, :bio, :banner_image, :address,
      :instagram_handle, :facebook_url, :website_url, :venmo_handle, :paypal_url
    )
  end
end
