module Storefront
  class ProfilesController < ApplicationController
    def show
      @store = Store.find_by!(slug: params[:slug])
    end
  end
end
