class DashboardController < ApplicationController
  before_action :require_authentication!
  before_action :set_store, only: [:show, :qr, :dismiss_onboarding]
  before_action :require_store!, only: [:show, :qr]
  layout "bakery", only: [:show]

  def show
    @drafts = @store.events.draft.includes(:event_products).order(pickup_starts_at: :asc)
    @upcoming = @store.events.published.where("pickup_starts_at >= ?", Time.current).includes(:orders).order(pickup_starts_at: :asc)
    @live = @upcoming.select(&:orders_open?)
    @prep = @upcoming.select(&:orders_closed?)
  end

  def qr
    return redirect_to billing_upgrade_path, alert: "QR codes are a Pro feature. Upgrade to unlock." if current_user.free?

    @shop_url = shop_url(@store.slug)
    @qr_svg = RQRCode::QRCode.new(@shop_url).as_svg(
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
    redirect_to dashboard_path
  end
end
