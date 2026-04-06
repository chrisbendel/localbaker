module Settings
  class AccountsController < BaseController
    # Skip set_store redirect if the user doesn't have a store yet
    # but still wants to edit their account settings.
    skip_before_action :set_store

    def show
    end

    def update
      if current_user.update(account_params)
        redirect_to settings_account_path, notice: "Account settings updated."
      else
        render :show, status: :unprocessable_entity
      end
    end

    private

    def account_params
      params.expect(user: [:name])
    end
  end
end
