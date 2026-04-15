module Dashboard
  class ProfilesController < BaseController
    def show
    end

    def update
      if @store.update(profile_params)
        redirect_to dashboard_profile_path, notice: "Baker profile updated."
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
