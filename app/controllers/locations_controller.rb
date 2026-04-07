class LocationsController < ApplicationController
  def near
    @latitude = params[:latitude]
    @longitude = params[:longitude]
    @address = params[:address]
    @radius = (params[:radius].presence || 25).to_i
    @tab = params[:tab].presence || "bakeries"

    if @address.present?
      results = Geocoder.search(@address)
      if results.any?
        @latitude = results.first.latitude
        @longitude = results.first.longitude
      end
    end

    if @latitude.present? && @longitude.present?
      @stores = ProximityService.stores_near(@latitude, @longitude, @radius)
        .joins(:events)
        .merge(Event.active_published)
        .distinct
      @events = ProximityService.events_near(@latitude, @longitude, @radius)
    else
      @stores = []
      @events = []
    end
  end
end
