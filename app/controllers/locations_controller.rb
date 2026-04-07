class LocationsController < ApplicationController
  def near
    @latitude = params[:latitude]
    @longitude = params[:longitude]
    @address = params[:address]
    @radius = (params[:radius].presence || 25).to_i.clamp(1, 100)
    @tab = params[:tab].presence || "bakeries"

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
      @stores = ProximityService.stores_near(@latitude, @longitude, @radius)
        .joins(:events)
        .merge(Event.active_published)
        .distinct
        .limit(10)

      store_ids = @stores.distinct.pluck(:id)
      @next_events_by_store = Event.active_published
        .where(store_id: store_ids)
        .order(:pickup_at)
        .group_by(&:store_id)
        .transform_values(&:first)
      @events = ProximityService.events_near(@latitude, @longitude, @radius)
    else
      @stores = []
      @next_events_by_store = {}
      @events = []
    end
  end
end
