module Settings
  class StoresController < BaseController
    def show
    end

    def update
      if params[:store][:remove_banner_image] == "1"
        @store.banner_image.purge
      end

      if @store.update(store_params)
        redirect_to settings_store_path, notice: "Store settings updated."
      else
        render :show, status: :unprocessable_entity
      end
    end

    private

    def store_params
      params.expect(store: [:name, :slug, :description, :address, :banner_image, :remove_banner_image, :venmo_handle, :paypal_url, :bio, :instagram_handle, :facebook_url, :website_url])
    end
  end
end
