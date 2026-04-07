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
      params.expect(store: [:name, :slug, :description, :address, :banner_image, :remove_banner_image,
        :delivery_zone_type, :delivery_zone_radius_miles, :delivery_zone_postal_codes])
    end
  end
end
