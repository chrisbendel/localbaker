module Settings
  class AccountsController < BaseController
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
      params.expect(user: [:name, :address])
    end
  end
end
