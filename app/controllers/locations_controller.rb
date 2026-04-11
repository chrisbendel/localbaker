class LocationsController < ApplicationController
  def near
    @latitude = params[:latitude]
    @longitude = params[:longitude]
    @address = params[:address]
    @radius = (params[:radius].presence || 25).to_i.clamp(1, 100)

    if @address.present?
      results = Geocoder.search(@address)
      if results.any?
        @latitude = results.first.latitude
        @longitude = results.first.longitude
      end
    end

    # Validate coordinates using strict parsing (not to_f which allows "abc" → 0.0)
    begin
      lat = Float(@latitude) if @latitude.present?
      lon = Float(@longitude) if @longitude.present?

      if lat && lon && (-90..90).cover?(lat) && (-180..180).cover?(lon)
        # Valid coordinates, keep them
      else
        @latitude = nil
        @longitude = nil
      end
    rescue ArgumentError
      # Invalid coordinate format
      @latitude = nil
      @longitude = nil
    end

    if @latitude.present? && @longitude.present?
      # Get nearby stores with published events (limit before materializing to save memory)
      nearby_stores = ProximityService.stores_near(@latitude, @longitude, @radius)
        .joins(:events)
        .merge(Event.orders_open)
        .reorder(nil)  # Clear Geocoder's ORDER BY distance since we can't select it after joins
        .distinct
        .limit(10)

      @stores = nearby_stores
      store_ids = @stores.pluck(:id)
      @next_events_by_store = Event.orders_open
        .where(store_id: store_ids)
        .order(:pickup_at)
        .group_by(&:store_id)
        .transform_values(&:first)
    else
      @stores = []
      @next_events_by_store = {}
    end
  end
end
