module Settings
  class ProfilesController < BaseController
    before_action :require_store!

    def show
    end

    def update
      if @store.update(profile_params)
        redirect_to settings_profile_path, notice: "Baker profile updated."
      else
        render :show, status: :unprocessable_entity
      end
    end

    private

    def profile_params
      params.expect(store: [:bio, :instagram_handle, :facebook_url, :website_url, :photo, :remove_photo])
    end
  end
end
