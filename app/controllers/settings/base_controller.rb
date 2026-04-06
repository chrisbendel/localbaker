module Settings
  class BaseController < ApplicationController
    before_action :require_authentication!
    before_action :set_store
    layout "settings"

    private

    def set_store
      @store = current_user.store
      # Redirect baker-specific settings back to store creation if missing
      unless @store || controller_name == "accounts"
        redirect_to new_store_path, notice: "Please create your store first."
      end
    end
  end
end
