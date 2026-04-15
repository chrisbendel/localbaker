module Dashboard
  class BaseController < ApplicationController
    before_action :require_authentication!
    before_action :set_store
    before_action :require_store!
    layout "bakery"

    protected

    def set_store
      @store = current_user.store
    end

    def require_store!
      redirect_to new_dashboard_path, alert: "You must create a store first." unless @store&.persisted?
    end
  end
end
