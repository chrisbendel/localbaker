module Settings
  class BaseController < ApplicationController
    before_action :require_authentication!
    before_action :set_store
    layout "settings"

    private

    def set_store
      @store = current_user.store
    end

    def require_store!
      redirect_to settings_account_path, alert: "You must create a store first." unless @store&.persisted?
    end
  end
end
