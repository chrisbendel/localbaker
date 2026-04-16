class SitemapsController < ApplicationController
  def index
    @stores = Store.listed
    @events = Event.active_published
  end
end
