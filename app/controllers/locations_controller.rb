class LocationsController < ApplicationController
  def near
    @latitude = params[:latitude]
    @longitude = params[:longitude]
    @radius = params[:radius].to_i.presence || 25
    @tab = params[:tab].presence || "bakeries"

    if @latitude.present? && @longitude.present?
      @stores = ProximityService.stores_near(@latitude, @longitude, @radius)
        .select { |store| store.events.active_published.any? }
      @events = ProximityService.events_near(@latitude, @longitude, @radius)
    else
      @stores = []
      @events = []
    end
  end
end
