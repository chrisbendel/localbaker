module Dashboard
  class BaseController < ApplicationController
    before_action :require_authentication!
    before_action :set_store
    before_action :require_store!
    layout "bakery"

    protected
  end
end
