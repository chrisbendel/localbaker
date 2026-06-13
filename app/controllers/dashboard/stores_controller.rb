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

    def qr
      @shop_url = shop_url(@store.slug)
      @qr_svg = RQRCode::QRCode.new(@shop_url).as_svg(
        color: "000",
        shape_rendering: "crispEdges",
        module_size: 6,
        standalone: true,
        use_path: true
      )
      render layout: "qr"
    end

    def update
      if @store.update(store_params)
        redirect_to dashboard_store_path, notice: "Store settings updated."
      else
        render :show, status: :unprocessable_entity
      end
    end

    def add_photos
      photos = Array(params[:gallery_photos]).select(&:present?)

      if photos.empty?
        redirect_to dashboard_store_path, alert: "Choose at least one photo."
      elsif photos.any? { |p| !p.content_type.to_s.start_with?("image/") }
        # accept="image/*" is client-side only; a non-image blob would 500
        # the storefront when variant() tries to process it.
        redirect_to dashboard_store_path, alert: "Photos must be image files."
      elsif @store.gallery_photos.count + photos.size > Store::GALLERY_PHOTO_LIMIT
        redirect_to dashboard_store_path, alert: "Photos are limited to #{Store::GALLERY_PHOTO_LIMIT}."
      else
        @store.gallery_photos.attach(photos)
        redirect_to dashboard_store_path, notice: "Photos added."
      end
    end

    def set_cover_photo
      photo = @store.gallery_photos.find(params[:photo_id])
      @store.update!(cover_photo_id: photo.id)
      redirect_to dashboard_store_path, notice: "Cover photo updated."
    end

    def remove_photo
      @store.gallery_photos.find(params[:photo_id]).purge
      redirect_to dashboard_store_path, notice: "Photo removed."
    end

    def destroy
      @store.destroy!
      redirect_to root_path, notice: "Store deleted."
    end

    private

    def store_params
      permitted = [:name, :slug, :description, :address, :listed, :contact_email, :contact_phone]
      permitted += [:delivery_zone_type, :delivery_zone_radius_miles, :delivery_zone_postal_codes] if current_user.pro?
      params.expect(store: permitted)
    end
  end
end
