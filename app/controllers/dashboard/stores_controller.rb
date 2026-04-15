module Dashboard
  class StoresController < BaseController
    skip_before_action :require_store!, only: [:new, :create]

    def new
      redirect_to dashboard_path if @store
      @store = Store.new
    end

    def create
      @store = Store.new(store_params)
      @store.user = current_user

      if @store.save
        redirect_to dashboard_path, notice: "Bakery created! Welcome to LocalBaker."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def show
      # Renders edit/settings form by default
    end

    def update
      if @store.update(store_params)
        redirect_to dashboard_store_path, notice: "Store settings updated."
      else
        render :show, status: :unprocessable_entity
      end
    end

    def destroy
      @store.destroy!
      redirect_to root_path, notice: "Store deleted."
    end

    private

    def store_params
      permitted = [:name, :slug, :description, :address, :listed, :banner_image, :remove_banner_image]
      permitted += [:delivery_zone_type, :delivery_zone_radius_miles, :delivery_zone_postal_codes] if current_user.pro?
      params.expect(store: permitted)
    end
  end
end
