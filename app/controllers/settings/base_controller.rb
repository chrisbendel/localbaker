module Settings
  class BaseController < ApplicationController
    before_action :require_authentication!
    before_action :set_store
    layout "settings"

    private

    def set_store
      @store = current_user.store
    end
  end
end
