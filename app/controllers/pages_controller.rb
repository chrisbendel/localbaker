class PagesController < ApplicationController
  def root
    if authenticated?
      if current_user.store&.persisted?
        redirect_to store_path
      else
        redirect_to near_path
      end
    else
      render :home
    end
  end

  def home
  end

  def about
  end
end
