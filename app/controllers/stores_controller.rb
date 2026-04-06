class StoresController < ApplicationController
  before_action :require_authentication!
  before_action :set_store, only: [:show, :qr, :dismiss_onboarding, :destroy]

  def new
    redirect_to store_path if current_user.store
    @store = Store.new
  end

  def create
    @store = Store.new(store_params)
    @store.user = current_user

    if @store.save
      redirect_to store_path, notice: "Bakery created! Welcome to LocalBaker."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @drafts = @store.events.draft.includes(:event_products).order(pickup_at: :asc)
    @upcoming = @store.events.published.where("pickup_at >= ?", Time.current).includes(:orders).order(pickup_at: :asc)
    @live = @upcoming.select(&:orders_open?)
    @prep = @upcoming.select(&:orders_closed?)
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
    @store.destroy!
    redirect_to root_path, notice: "Store deleted."
  end

  private

  def set_store
    @store = current_user.store
    redirect_to new_store_path unless @store
  end

  def store_params
    params.expect(store: [:name, :slug, :address, :description])
  end
end
