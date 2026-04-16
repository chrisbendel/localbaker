module Dashboard
  class BaseController < ApplicationController
    before_action :require_authentication!
    before_action :set_store
    before_action :require_store!
    layout "bakery"

    protected

    def require_pro!
      redirect_to billing_upgrade_path, alert: "This feature is available for Pro members. Upgrade today!" unless current_user.pro?
    end
  end
end
