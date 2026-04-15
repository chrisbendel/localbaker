class DashboardController < ApplicationController
  before_action :require_authentication!
  before_action :set_store, only: [:show, :dismiss_onboarding]
  before_action :require_store!, only: [:show]
  layout "bakery", only: [:show]

  def show
    @drafts = @store.events.draft.includes(:event_products).order(pickup_starts_at: :asc)
    @upcoming = @store.events.published.where("pickup_starts_at >= ?", Time.current).includes(:orders).order(pickup_starts_at: :asc)
    @live = @upcoming.select(&:orders_open?)
    @prep = @upcoming.select(&:orders_closed?)
  end

  def dismiss_onboarding
    session[:onboarding_dismissed] = true
    redirect_to dashboard_path
  end
end
