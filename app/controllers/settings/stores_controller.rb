module Settings
  class StoresController < BaseController
    before_action :require_store!

    def show
    end

    def update
      if @store.update(store_params)
        redirect_to settings_store_path, notice: "Store settings updated."
      else
        render :show, status: :unprocessable_entity
      end
    end

    private

    def store_params
      permitted = [:name, :slug, :description, :address, :banner_image, :remove_banner_image]
      permitted += [:delivery_zone_type, :delivery_zone_radius_miles, :delivery_zone_postal_codes] if current_user.pro?
      params.expect(store: permitted)
    end
  end
end
